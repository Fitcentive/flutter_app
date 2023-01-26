import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum RadioOption { yes, no }

class GymPreferenceView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final bool? doesUserHaveGym;

  const GymPreferenceView({
    Key? key,
    required this.userProfile,
    required this.doesUserHaveGym,
  }): super(key: key);

  @override
  State createState() {
    return GymPreferenceViewState();
  }
}

class GymPreferenceViewState extends State<GymPreferenceView> {

  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  RadioOption? selectedOption;

  @override
  void initState() {
    super.initState();
    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);

    selectedOption = (widget.doesUserHaveGym ?? false) ? RadioOption.yes : RadioOption.no;
    _updateBlocState(selectedOption);

  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
              child: FittedBox(
                  child: Text("Do you currently go to a gym?", style: TextStyle(fontSize: 20),
                  )
              )
          ),
          WidgetUtils.spacer(10),
          ListTile(
            title: const Text('No', style: TextStyle(fontSize: 15)),
            leading: Radio<RadioOption>(
              fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                 return Colors.teal;
               }),
              value: RadioOption.no,
              groupValue: selectedOption,
              onChanged: (RadioOption? value) {
                setState(() {
                  selectedOption = value;
                  _updateBlocState(value);
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Yes', style: TextStyle(fontSize: 15)),
            leading: Radio<RadioOption>(fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                return Colors.teal;
              }),
              value: RadioOption.yes,
              groupValue: selectedOption,
              onChanged: (RadioOption? value) {
                setState(() {
                  selectedOption = value;
                  _updateBlocState(value);
                });
              },
            ),
          ),
          WidgetUtils.spacer(10),
        ],
      ),
    );
  }

  _updateBlocState(RadioOption? radioSelection) {
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
        preferredDays: currentState.preferredDays,
        minimumAge: currentState.minimumAge,
        maximumAge: currentState.maximumAge,
        hoursPerWeek: currentState.hoursPerWeek,
        hasGym: radioSelection == RadioOption.yes,
        gymLocationId: currentState.gymLocationId,
        gymLocationFsqId: currentState.gymLocationFsqId,
      ));
    }
  }

}