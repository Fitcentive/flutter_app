import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityPreferencesView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final List<String>? activitiesInterestedIn;

  const ActivityPreferencesView({
    Key? key,
    required this.userProfile,
    required this.activitiesInterestedIn,
  }): super(key: key);

  @override
  State createState() {
    return ActivityPreferencesViewState();
  }
}

class ActivityPreferencesViewState extends State<ActivityPreferencesView> {
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  List<String> selectedActivities = List<String>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    selectedActivities = widget.activitiesInterestedIn ?? List.empty(growable: true);
    _updateBlocState(selectedActivities);
  }

  @override
  Widget build(BuildContext context) {
    final activities = ConstantUtils.activityTypes.map((activity) => _createCheckbox(activity)).toList();
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Which of these activities do you enjoy?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(5),
              const Text("Select all that apply", style: TextStyle(fontSize: 15),),
              WidgetUtils.spacer(20),
              ...activities
            ],
          ),
        ),
      ),
    );
  }

  Widget _createCheckbox(String entity) {
    return CheckboxListTile(
        value: selectedActivities.contains(entity),
        title: Text(entity),
        onChanged: (newValue) {
          if (newValue != null) {
            if (newValue) {
              selectedActivities.add(entity);
            }
            else {
              selectedActivities.remove(entity);
            }
            _updateBlocState(selectedActivities);
          }
        }
    );
  }

  _updateBlocState(List<String> newSelectedActivities) {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      _discoverUserPreferencesBloc.add(UserDiscoverPreferencesChanged(
        userProfile: widget.userProfile,
        locationCenter: currentState.locationCenter,
        locationRadius: currentState.locationRadius,
        preferredTransportMode: currentState.preferredTransportMode,
        activitiesInterestedIn: newSelectedActivities,
        fitnessGoals: currentState.fitnessGoals,
        desiredBodyTypes: currentState.desiredBodyTypes,
        gendersInterestedIn: currentState.gendersInterestedIn,
        preferredDays: currentState.preferredDays,
        minimumAge: currentState.minimumAge,
        maximumAge: currentState.maximumAge,
        hoursPerWeek: currentState.hoursPerWeek,
      ));
      setState(() {
        selectedActivities = newSelectedActivities;
      });
    }
  }

}