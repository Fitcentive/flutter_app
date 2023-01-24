import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_app/src/views/shared_components/provide_location_view.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GymLocationsView extends StatefulWidget {
  final PublicUserProfile userProfile;

  const GymLocationsView({
    Key? key,
    required this.userProfile,
  }): super(key: key);

  @override
  State createState() {
    return GymLocationsViewState();
  }
}

class GymLocationsViewState extends State<GymLocationsView> {

  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  late double latitude;
  late double longitude;
  late int radius;

  @override
  void initState() {
    super.initState();
    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);

    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      latitude = currentState.locationCenter!.latitude;
      longitude = currentState.locationCenter!.longitude;
      radius = currentState.locationRadius!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchLocationsView.withBloc(
            latitude: latitude,
            longitude: longitude,
            radius: radius.toDouble(),
            updateBlocCallback: () {}
        )
      ],
    );
  }

  _updateBlocState(String gymLocationId) {
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
          hasGym: currentState.hasGym,
          gymLocationId: gymLocationId
      ));
    }
  }

}