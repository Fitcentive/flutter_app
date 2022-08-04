import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DaysPreferencesView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final List<String>? preferredDays;
  final double? hoursPerWeek;

  const DaysPreferencesView({
    Key? key,
    required this.userProfile,
    required this.preferredDays,
    required this.hoursPerWeek,
  }): super(key: key);

  @override
  State createState() {
    return DaysPreferencesViewState();
  }
}

class DaysPreferencesViewState extends State<DaysPreferencesView> {
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  List<String> selectedDays = List<String>.empty(growable: true);
  double selectedHoursPerWeek = ConstantUtils.defaultSelectedHoursPerWeek;


  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    selectedDays = widget.preferredDays ?? List.empty(growable: true);
    selectedHoursPerWeek = widget.hoursPerWeek ?? ConstantUtils.defaultSelectedHoursPerWeek;

    _updateBlocState(selectedDays, selectedHoursPerWeek);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("What days are you available?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(5),
              const Text("Select all that apply", style: TextStyle(fontSize: 15),),
              WidgetUtils.spacer(20),
              _createCheckbox("Sunday"),
              _createCheckbox("Monday"),
              _createCheckbox("Tuesday"),
              _createCheckbox("Wednesday"),
              _createCheckbox("Thursday"),
              _createCheckbox("Friday"),
              _createCheckbox("Saturday"),
              WidgetUtils.spacer(20),
              const Text("How many hours a week are you willing to commit?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(5),
              const Text("This can be changed later", style: TextStyle(fontSize: 15),),
              WidgetUtils.spacer(10),
              _createHoursPerWeekSlider(),
              Text(_getLabel(selectedHoursPerWeek))
            ],
          ),
        ),
      ),
    );
  }

  _createHoursPerWeekSlider() {
    return SliderTheme(
        data: const SliderThemeData(
          overlayColor: Colors.tealAccent,
          valueIndicatorColor: Colors.teal,
        ),
        child: Slider(
          value: selectedHoursPerWeek,
          max: 10.25,
          divisions: 41,
          label: _getLabel(selectedHoursPerWeek),
          onChanged: (newValue) {
            setState(() {
              selectedHoursPerWeek = newValue;
              _updateBlocState(selectedDays, selectedHoursPerWeek);
            });
          },
        )
    );
  }

  _getLabel(double selectedValue) {
    if (selectedValue < 10) {
      return "${selectedValue.toStringAsFixed(2)} hours/week";
    }
    else {
      return "10+ hours/week";
    }
  }

  _createCheckbox(String entity) {
    return CheckboxListTile(
        value: selectedDays.contains(entity),
        title: Text(entity),
        onChanged: (newValue) {
          if (newValue != null) {
            if (newValue) {
              selectedDays.add(entity);
            }
            else {
              selectedDays.remove(entity);
            }
            _updateBlocState(selectedDays, selectedHoursPerWeek);
          }
        }
    );
  }

  _updateBlocState(List<String> newDays, double newHoursPerWeek) {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      _discoverUserPreferencesBloc.add(UserDiscoverPreferencesChanged(
        userProfile: widget.userProfile,
        locationCenter: currentState.locationCenter,
        locationRadius: currentState.locationRadius,
        preferredTransportMode: currentState.preferredTransportMode,
        activitiesInterestedIn: currentState.activitiesInterestedIn,
        fitnessGoals: currentState.fitnessGoals,
        desiredBodyTypes: currentState.desiredBodyTypes,
        gendersInterestedIn: currentState.gendersInterestedIn,
        preferredDays: newDays,
        minimumAge: currentState.minimumAge,
        maximumAge: currentState.maximumAge,
        hoursPerWeek: newHoursPerWeek,
      ));
      setState(() {
        selectedDays = newDays;
        selectedHoursPerWeek = newHoursPerWeek;
      });
    }
  }

}