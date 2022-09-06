import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationView extends StatelessWidget {
  static const String routeName = "discovery/recommendation/location";

  final PublicUserProfile userProfile;

  LocationView({
    Key? key,
    required this.userProfile,
  }): super(key: key);

  static Route route(PublicUserProfile userProfile) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => LocationView(userProfile: userProfile)
    );
  }

  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  CircleId circleId = const CircleId('radius_circle');

  late CameraPosition initialCameraPosition;

  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late double currentSliderValue;
  late LatLng currentCentrePosition;

  void _generateBoundaryCircle() {
    circles.clear();
    final Circle circle = Circle(
      circleId: circleId,
      consumeTapEvents: true,
      strokeColor: Colors.tealAccent,
      fillColor: Colors.teal.withOpacity(0.5),
      strokeWidth: 5,
      center: currentCentrePosition,
      radius: currentSliderValue * 1000,
    );
    circles[circleId] = circle;
  }

  _setupMap() {
    currentSliderValue = userProfile.locationRadius! / 1000;
    currentCentrePosition = LatLng(userProfile.locationCenter!.latitude, userProfile.locationCenter!.longitude);
    initialCameraPosition =  CameraPosition(
        target: currentCentrePosition,
        zoom: LocationUtils.getZoomLevel(userProfile.locationRadius!.toDouble())
    );
    _generateBoundaryCircle();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentCentrePosition,
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