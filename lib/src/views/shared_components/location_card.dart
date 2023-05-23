import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/views/shared_components/location_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationCard extends StatelessWidget {
  final PublicUserProfile currentUserProfile;
  final PublicUserProfile otherUserProfile;

  LocationCard({
    Key? key,
    required this.otherUserProfile,
    required this.currentUserProfile,
  }) : super(key: key);

  late int otherUserLocationRadius;
  late LatLng otherUserProfileLocationCenter;
  late int currentUserLocationRadius;
  late LatLng currentUserProfileLocationCenter;

  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();
  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  void _generateBoundaryCircle(
      String userId,
      LatLng position,
      int radius,
      Color fillColor,
      Color strokeColor,
      BuildContext context
  ) {
    final cId = CircleId(userId);
    final Circle circle = Circle(
      circleId: cId,
      strokeColor: strokeColor,
      consumeTapEvents: true,
      onTap: () {
        _goToLocationView(otherUserProfile, currentUserProfile, context);
      },
      fillColor: fillColor.withOpacity(0.5),
      strokeWidth: 5,
      center: position,
      radius: radius.toDouble(),
    );
    circles[cId] = circle;
  }

  _setupMap(PublicUserProfile otherUser, PublicUserProfile currentUser, BuildContext context) {
    otherUserLocationRadius = otherUser.locationRadius ?? 1000;
    // Use user profile location - otherwise use default location
    otherUserProfileLocationCenter = otherUser.locationCenter != null ?
      LatLng(otherUser.locationCenter!.latitude, otherUser.locationCenter!.longitude) : LocationUtils.defaultLocation;

    currentUserLocationRadius = currentUser.locationRadius ?? 1000;
    // Use user profile location - otherwise use default location
    currentUserProfileLocationCenter = currentUser.locationCenter != null ?
    LatLng(currentUser.locationCenter!.latitude, currentUser.locationCenter!.longitude) : LocationUtils.defaultLocation;

    _initialCameraPosition = CameraPosition(
        target: LocationUtils.computeCentroid(
            [otherUserProfileLocationCenter, currentUserProfileLocationCenter]
                .toList()
                .map((e) => LatLng(e.latitude, e.longitude))),
        tilt: 0,
        zoom: LocationUtils.getZoomLevelMini(
            [otherUserLocationRadius, currentUserLocationRadius]
                .reduce(max)
                .toDouble())
    );

    circles.clear();
    _generateBoundaryCircle(otherUser.userId, otherUserProfileLocationCenter, otherUserLocationRadius, Colors.blue, Colors.blueAccent, context);
    _generateBoundaryCircle(currentUser.userId, currentUserProfileLocationCenter, currentUserLocationRadius, Colors.teal, Colors.tealAccent, context);

    markers.clear();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentUserProfileLocationCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setupMap(otherUserProfile, currentUserProfile, context);
    return GoogleMap(
        onTap: (_) {
          _goToLocationView(otherUserProfile, currentUserProfile, context);
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
    );
  }

  _goToLocationView(PublicUserProfile userProfile, PublicUserProfile currentUserProfile, BuildContext context,) {
    Navigator.push(
      context,
      LocationView.route(userProfile, currentUserProfile),
    );
  }

}