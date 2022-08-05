import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/views/shared_components/location_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationCard extends StatelessWidget {
  final PublicUserProfile userProfile;

  LocationCard({Key? key, required this.userProfile}) : super(key: key);

  late int locationRadius;
  late LatLng currentUserProfileLocationCenter;
  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();
  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  CircleId circleId = const CircleId('radius_circle');
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  void _generateBoundaryCircle(LatLng position, int radius, BuildContext context) {
    circles.clear();
    final Circle circle = Circle(
      circleId: circleId,
      strokeColor: Colors.tealAccent,
      consumeTapEvents: true,
      onTap: () {
        _goToLocationView(userProfile, context);
      },
      fillColor: Colors.teal.withOpacity(0.5),
      strokeWidth: 5,
      center: position,
      radius: radius.toDouble(),
    );
    circles[circleId] = circle;
  }

  _setupMap(PublicUserProfile user, BuildContext context) {
    locationRadius = user.locationRadius ?? 1000;

    // Use user profile location - otherwise use default location
    currentUserProfileLocationCenter = user.locationCenter != null ?
    LatLng(user.locationCenter!.latitude, user.locationCenter!.longitude) : LocationUtils.defaultLocation;

    _initialCameraPosition = CameraPosition(
        target: currentUserProfileLocationCenter,
        tilt: 0,
        zoom: LocationUtils.getZoomLevelMini(locationRadius.toDouble())
    );

    _generateBoundaryCircle(currentUserProfileLocationCenter, locationRadius, context);
    markers.clear();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentUserProfileLocationCenter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setupMap(userProfile, context);
    return SizedBox(
      height: 125,
      child: GoogleMap(
          onTap: (_) {
            _goToLocationView(userProfile, context);
          },
          mapType: MapType.hybrid,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          markers: markers,
          circles: Set<Circle>.of(circles.values),
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: (GoogleMapController controller) {
            _mapController.complete(controller);
          }
      ),
    );
  }

  _goToLocationView(PublicUserProfile userProfile, BuildContext context,) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      LocationView.route(userProfile),
        (route) => true
    );
  }

}