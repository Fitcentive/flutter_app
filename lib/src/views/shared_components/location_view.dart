import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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

  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late LatLng otherUserProfileLocationCenter;
  late LatLng currentUserProfileLocationCenter;

  late BitmapDescriptor customUserLocationMarker;

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
        icon: customUserLocationMarker
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
          _mapController.complete(controller);
        },
        markers: markers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Location", style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: FutureBuilder<int>(
        future: _setupMapIconsForUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _setupMap();
            return Stack(
              children: [
                _renderMap(context),
                _recenterButton(),
              ],
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      )
    );
  }

  _snapCameraToMarkers() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
        CameraUpdate.newLatLngBounds(
            LocationUtils.createBounds(circles.entries.map((e) => e.value.center).toList()),
            50
        )
    );
  }

  Widget _recenterButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: SizedBox(
          height: 40,
          width: 40,
          child: FloatingActionButton(
              heroTag: "LocationViewSnapToMarkersButton-${StringUtils.generateRandomString(10)}",
              onPressed: () {
                _snapCameraToMarkers();
              },
              backgroundColor: Colors.teal,
              tooltip: "Re-center",
              child: const Icon(
                  Icons.location_searching_outlined,
                  color: Colors.white,
                  size: 16
              )
          ),
        ),
      ),
    );
  }

  Future<int> _setupMapIconsForUsers() async {
    if (DeviceUtils.isAppRunningOnMobileBrowser()) {
      customUserLocationMarker = BitmapDescriptor.defaultMarker;
    }
    else {
      customUserLocationMarker = await _generateCustomMarkerForUser(currentUserProfile);
    }
    return 1;
  }

  _generateCustomMarkerForUser(PublicUserProfile userProfile) async {
    final fullImageUrl = ImageUtils.getFullImageUrl(userProfile.photoUrl, 96, 96);
    final request = await http.get(Uri.parse(fullImageUrl));
    return await ImageUtils.getMarkerIcon(request.bodyBytes, const Size(96, 96), Colors.teal);
  }
}