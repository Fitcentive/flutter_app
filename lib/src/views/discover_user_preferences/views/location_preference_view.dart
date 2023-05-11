import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_app/src/views/shared_components/provide_location_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPreferenceView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final LatLng? locationCenter;
  final int? locationRadius;

  const LocationPreferenceView({
    Key? key,
    required this.userProfile,
    required this.locationCenter,
    required this.locationRadius,
  }): super(key: key);

  @override
  State createState() {
    return LocationPreferenceViewState();
  }
}

class LocationPreferenceViewState extends State<LocationPreferenceView> {

  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  late double locationViewLatitude;
  late double locationViewLongitude;
  late int locationViewRadius;

  @override
  void initState() {
    super.initState();
    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);

    locationViewLatitude = widget.locationCenter?.latitude ?? widget.userProfile.locationCenter!.latitude;
    locationViewLongitude = widget.locationCenter?.longitude ?? widget.userProfile.locationCenter!.longitude;
    locationViewRadius = widget.locationRadius ?? widget.userProfile.locationRadius!;

    // Add initial values to bloc state so that user can simply accept current location as discovery location
    _updateBlocState(LatLng(locationViewLatitude, locationViewLongitude), locationViewRadius);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: FittedBox(
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: const Text("Tell us where you would like to find fitness buddies", style: TextStyle(fontSize: 16),)
                  )
              )
          ),
          WidgetUtils.spacer(10),
          ProvideLocationView(
            latitude: locationViewLatitude,
            longitude: locationViewLongitude,
            radius: locationViewRadius.toDouble(),
            updateBlocState: _updateBlocState,
            mapScreenHeightProportion: 0.6,
            mapControlsHeightProportion: 0.2,
          )
        ],
      ),
    );
  }

  _updateBlocState(LatLng coordinates, int radius) {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      _discoverUserPreferencesBloc.add(UserDiscoverPreferencesChanged(
          userProfile: widget.userProfile,
          locationCenter: coordinates,
          locationRadius: radius,
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
          gymLocationId: currentState.gymLocationId,
          gymLocationFsqId: currentState.gymLocationFsqId,
      ));
    }
  }

}