import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationView extends StatelessWidget {
  static const String routeName = "discovery/recommendation/location";

  final PublicUserProfile otherUserProfile;
  final PublicUserProfile currentUserProfile;

  LocationView({
    Key? key,
    required this.otherUserProfile,
    required this.currentUserProfile,
  }): super(key: key);

  static Route route(PublicUserProfile otherUserProfile, PublicUserProfile currentUserProfile) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => LocationView(otherUserProfile: otherUserProfile, currentUserProfile: currentUserProfile)
    );
  }

  MarkerId markerId = const MarkerId("camera_centre_marker_id");

  late CameraPosition initialCameraPosition;

  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late LatLng otherUserProfileLocationCenter;
  late LatLng currentUserProfileLocationCenter;

  void _generateBoundaryCircle(String userId, LatLng centrePosition, double radius, Color strokeColor, Color fillColor) {
    final cId = CircleId(userId);
    final Circle circle = Circle(
      circleId: cId,
      consumeTapEvents: true,
      strokeColor: strokeColor,
      fillColor: fillColor.withOpacity(0.5),
      strokeWidth: 5,
      center: centrePosition,
      radius: radius,
    );
    circles[cId] = circle;
  }

  _setupMap() {
    otherUserProfileLocationCenter = LatLng(otherUserProfile.locationCenter!.latitude, otherUserProfile.locationCenter!.longitude);
    currentUserProfileLocationCenter = LatLng(currentUserProfile.locationCenter!.latitude, currentUserProfile.locationCenter!.longitude);

    initialCameraPosition = CameraPosition(
        target: LocationUtils.computeCentroid(
            [otherUserProfileLocationCenter, currentUserProfileLocationCenter]
                .toList()
                .map((e) => LatLng(e.latitude, e.longitude))),
        tilt: 0,
        zoom: LocationUtils.getZoomLevelMini(
            [otherUserProfile.locationRadius!, currentUserProfile.locationRadius!]
                .reduce(max)
                .toDouble())
    );

    circles.clear();
    _generateBoundaryCircle(otherUserProfile.userId, otherUserProfileLocationCenter, otherUserProfile.locationRadius!.toDouble(), Colors.blueAccent, Colors.blue );
    _generateBoundaryCircle(currentUserProfile.userId, currentUserProfileLocationCenter, currentUserProfile.locationRadius!.toDouble(), Colors.tealAccent, Colors.teal );

    markers.add(
      Marker(
        markerId: markerId,
        position: currentUserProfileLocationCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
      ),
    );
  }

  _renderMap(BuildContext context) {
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context),
      child: GoogleMap(
        mapType: MapType.hybrid,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: initialCameraPosition,
        circles: Set<Circle>.of(circles.values),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: markers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setupMap();
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Location", style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _renderMap(context),
    );
  }
}