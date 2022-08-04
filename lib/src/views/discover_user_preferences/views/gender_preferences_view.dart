import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GenderPreferencesView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final List<String>? preferredGenders;
  final int? minimumAge;
  final int? maximumAge;

  const GenderPreferencesView({
    Key? key,
    required this.userProfile,
    required this.preferredGenders,
    required this.minimumAge,
    required this.maximumAge,
  }): super(key: key);

  @override
  State createState() {
    return GenderPreferencesViewState();
  }
}

class GenderPreferencesViewState extends State<GenderPreferencesView> {
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  List<String> selectedGenders = List<String>.empty(growable: true);
  int selectedMinimumAge = ConstantUtils.defaultMinimumAge;
  int selectedMaximumAge = ConstantUtils.defaultMaximumAge;
  RangeValues _ageRangeValues = RangeValues(
      ConstantUtils.defaultMinimumAge.toDouble(),
      ConstantUtils.defaultMaximumAge.toDouble()
  );

  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    selectedGenders = widget.preferredGenders ?? List.empty(growable: true);
    selectedMinimumAge = widget.minimumAge ?? ConstantUtils.defaultMinimumAge;
    selectedMaximumAge = widget.maximumAge ?? ConstantUtils.defaultMaximumAge;
    _ageRangeValues = RangeValues(selectedMinimumAge.toDouble(), selectedMaximumAge.toDouble());

    _updateBlocState(selectedGenders, selectedMinimumAge, selectedMaximumAge);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 50, 10, 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Whom would you prefer to connect with?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(5),
              const Text("Select all that apply", style: TextStyle(fontSize: 15),),
              WidgetUtils.spacer(20),
              _createCheckbox("Male"),
              _createCheckbox("Female"),
              _createCheckbox("Other"),
              WidgetUtils.spacer(50),
              const Text("What is your age preference?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(10),
              _createAgeSlider(),
              _createAgeSliderCurrentValues(),
            ],
          ),
        ),
      ),
    );
  }

  _createAgeSliderCurrentValues() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(selectedMinimumAge.toString(), style: const TextStyle(fontSize: 18),),
            const Text(" - ", style: TextStyle(fontSize: 18),),
            Text(selectedMaximumAge.toString(), style: const TextStyle(fontSize: 18),),
          ]
      ),
    );
  }

  _createAgeSlider() {
    return SliderTheme(
        data: const SliderThemeData(
          overlayColor: Colors.tealAccent,
          valueIndicatorColor: Colors.teal,

        ),
        child: RangeSlider(
          values: _ageRangeValues,
          min: ConstantUtils.defaultMinimumAge.toDouble(),
          max: ConstantUtils.defaultMaximumAge.toDouble(),
          divisions: 82,
          labels: RangeLabels(
            _ageRangeValues.start.round().toString(),
            _ageRangeValues.end.round().toString(),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _ageRangeValues = values;
              selectedMinimumAge = _ageRangeValues.start.toInt();
              selectedMaximumAge = _ageRangeValues.end.toInt();
              _updateBlocState(selectedGenders, selectedMinimumAge, selectedMaximumAge);
            });
          },
        )
    );
  }

  _createCheckbox(String entity) {
    return CheckboxListTile(
        value: selectedGenders.contains(entity),
        title: Text(entity),
        onChanged: (newValue) {
          if (newValue != null) {
            if (newValue) {
              selectedGenders.add(entity);
            }
            else {
              selectedGenders.remove(entity);
            }
            _updateBlocState(selectedGenders, selectedMinimumAge, selectedMaximumAge);
          }
        }
    );
  }

  _updateBlocState(List<String> newGenders, int newMinimumAge, int newMaximumAge) {
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
        gendersInterestedIn: newGenders,
        preferredDays: currentState.preferredDays,
        minimumAge: newMinimumAge,
        maximumAge: newMaximumAge,
        hoursPerWeek: currentState.hoursPerWeek,
      ));
      setState(() {
        selectedGenders = newGenders;
        selectedMinimumAge = newMinimumAge;
        selectedMaximumAge = newMaximumAge;
      });
    }
  }

}