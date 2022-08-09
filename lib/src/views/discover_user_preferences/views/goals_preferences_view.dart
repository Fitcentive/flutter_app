import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoalsPreferencesView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final List<String>? fitnessGoals;

  const GoalsPreferencesView({
    Key? key,
    required this.userProfile,
    required this.fitnessGoals,
  }): super(key: key);

  @override
  State createState() {
    return GoalsPreferencesViewState();
  }
}

class GoalsPreferencesViewState extends State<GoalsPreferencesView> {
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  List<String> selectedGoals = List<String>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    selectedGoals = widget.fitnessGoals ?? List.empty(growable: true);
    _updateBlocState(selectedGoals);
  }

  @override
  Widget build(BuildContext context) {
    final goals = ConstantUtils.fitnessGoals.map((g) => _createCheckbox(g)).toList();
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("What are your goals?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(5),
              const Text("Select all that apply", style: TextStyle(fontSize: 15),),
              WidgetUtils.spacer(20),
              ...goals,
            ],
          ),
        ),
      ),
    );
  }

  _createCheckbox(String entity) {
    return CheckboxListTile(
        value: selectedGoals.contains(entity),
        title: Text(entity),
        onChanged: (newValue) {
          if (newValue != null) {
            if (newValue) {
              selectedGoals.add(entity);
            }
            else {
              selectedGoals.remove(entity);
            }
            _updateBlocState(selectedGoals);
          }
        }
    );
  }

  _updateBlocState(List<String> newGoals) {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      _discoverUserPreferencesBloc.add(UserDiscoverPreferencesChanged(
        userProfile: widget.userProfile,
        locationCenter: currentState.locationCenter,
        locationRadius: currentState.locationRadius,
        preferredTransportMode: currentState.preferredTransportMode,
        activitiesInterestedIn: currentState.activitiesInterestedIn,
        fitnessGoals: newGoals,
        desiredBodyTypes: currentState.desiredBodyTypes,
        gendersInterestedIn: currentState.gendersInterestedIn,
        preferredDays: currentState.preferredDays,
        minimumAge: currentState.minimumAge,
        maximumAge: currentState.maximumAge,
        hoursPerWeek: currentState.hoursPerWeek,
      ));
      setState(() {
        selectedGoals = newGoals;
      });
    }
  }

}