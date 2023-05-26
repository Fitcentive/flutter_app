import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/shared_components/location_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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

  late BitmapDescriptor customUserLocationMarker;

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
        icon: customUserLocationMarker
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _setupMapIconsForUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // _setupMap(widget.meetupLocation, widget.userProfiles);
          _setupMap(otherUserProfile, currentUserProfile, context);
          return Stack(
            children: [
              _mapView(context),
              _recenterButton(),
            ],
          );
        }
        else {
          if (snapshot.hasError) {
            /**
             * main.dart.js:42078 Future failed with error:
             * NoSuchMethodError: method not found: 'toString' on null
             */
            print("Future failed with error: ${snapshot.error}");
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  _snapCameraToCircles() async {
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
              heroTag: "LocationCardViewSnapToMarkersButton-${StringUtils.generateRandomString(10)}",
              onPressed: () {
                _snapCameraToCircles();
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

  Widget _mapView(BuildContext context) {
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