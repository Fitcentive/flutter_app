import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class MeetupLocationView extends StatefulWidget {
  final VoidCallback onTapCallback;

  final MeetupLocation? meetupLocation;
  final List<PublicUserProfile> userProfiles;
  final PublicUserProfile currentUserProfile;

  const MeetupLocationView({
    super.key,
    this.meetupLocation,
    required this.currentUserProfile,
    required this.userProfiles,
    required this.onTapCallback,
  });


  @override
  State createState() {
    return MeetupLocationViewState();
  }
}

class MeetupLocationViewState extends State<MeetupLocationView> {

  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();
  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  CircleId circleId = const CircleId('radius_circle');
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  Map<String, BitmapDescriptor?> userIdToMapMarkerIcon = {};
  Map<String, Color> userIdToMapMarkerColor = {};
  List<Color> usedColoursThusFar = [];

  late BitmapDescriptor customGymLocationIcon;

  @override
  void initState() {
    super.initState();

    _setupColorsForUsers(widget.userProfiles);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _setupMapIconsForUsers(widget.userProfiles),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _setupMap(widget.meetupLocation, widget.userProfiles);
          return Stack(
            children: [
              _mapView(),
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
    );
  }

  Widget _mapView() {
    return GoogleMap(
        onTap: (_) {
          widget.onTapCallback();
        },
        mapType: MapType.normal,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        markers: markers,
        circles: Set<Circle>.of(circles.values),
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
          // _snapCameraToMarkers();
        },
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>> {
          Factory<OneSequenceGestureRecognizer> (() => EagerGestureRecognizer()),
        }
    );
  }

  Widget _recenterButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: PointerInterceptor(
          child: SizedBox(
            height: 40,
            width: 40,
            child: FloatingActionButton(
                heroTag: "MeetupLocationViewSnapToMarkersButton-${StringUtils.generateRandomString(10)}",
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
      ),
    );
  }

  Future<int> _setupMapIconsForUsers(List<PublicUserProfile> users) async {
    _setupColorsForUsers(users);

    if (DeviceUtils.isAppRunningOnMobileBrowser()) {
      for (var e in users) {
        if (userIdToMapMarkerIcon[e.userId] == null) {
          userIdToMapMarkerIcon[e.userId] = BitmapDescriptor.defaultMarker;
        }
      }
      customGymLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    else {
      for (var e in users) {
        if (userIdToMapMarkerIcon[e.userId] == null) {
          userIdToMapMarkerIcon[e.userId] = await _generateCustomMarkerForUser(e);
        }
      }
      // Note - https://docs.flutter.dev/ui/assets-and-images#declaring-resolution-aware-image-assets
      //       BitmapDescriptor.fromAssetImage(configuration, assetName) is an option to try as well
      final Uint8List? gymMarkerIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon.png', 100);
      customGymLocationIcon = BitmapDescriptor.fromBytes(gymMarkerIcon!);
    }

    return 1;
  }

  // Max 7 other colors! or errors
  _setupColorsForUsers(List<PublicUserProfile> users) {
    userIdToMapMarkerColor[widget.currentUserProfile.userId] = Colors.teal;
    usedColoursThusFar.add(Colors.teal);

    users
        .where((e) => e.userId != widget.currentUserProfile.userId)
        .toList()
        .asMap()
        .forEach((index, u) {
          var nextColor = userIdToMapMarkerColor[u.userId];
          if (nextColor == null) {
              nextColor = ColorUtils.circleColoursWithoutTeal[index];
              userIdToMapMarkerColor[u.userId] = nextColor;
              usedColoursThusFar.add(nextColor);
            }
          }
    );
  }

  _generateCustomMarkerForUser(PublicUserProfile userProfile) async {
    final fullImageUrl = ImageUtils.getFullImageUrl(userProfile.photoUrl, 96, 96);
    final request = await http.get(Uri.parse(fullImageUrl));
    return await ImageUtils.getMarkerIcon(request.bodyBytes, const Size(96, 96), userIdToMapMarkerColor[userProfile.userId]!);
  }


  void _generateCircleAndMarkerForUserProfile(PublicUserProfile profile, BitmapDescriptor markerIcon) {
    final newCircleId = CircleId(profile.userId);
    final Circle circle = Circle(
      circleId: newCircleId,
      strokeColor: userIdToMapMarkerColor[profile.userId]!,
      consumeTapEvents: false,
      onTap: () {
        // _goToLocationView(userProfile, context);
      },
      fillColor: userIdToMapMarkerColor[profile.userId]!.withOpacity(0.25),
      strokeWidth: 3,
      center: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      radius: profile.locationRadius!.toDouble(),
    );
    circles[newCircleId] = circle;

    markers.add(
      Marker(
        icon: markerIcon,
        markerId: MarkerId(profile.userId),
        position: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      ),
    );
  }

  _setupMap(MeetupLocation? meetupLocation, List<PublicUserProfile> users) {
    markers.clear();
    circles.clear();

    // Generate user markers
    users.forEach((user) {
      final BitmapDescriptor theCustomMarkerToUse = userIdToMapMarkerIcon[user.userId]!;
      _generateCircleAndMarkerForUserProfile(user, theCustomMarkerToUse);
    });

    // Generate selected location marker
    if (meetupLocation != null) {
      markers.add(
        Marker(
          icon: customGymLocationIcon,
          markerId: MarkerId(meetupLocation.id),
          position: LatLng(meetupLocation.coordinates.latitude, meetupLocation.coordinates.longitude),
        ),
      );
    }

    _initialCameraPosition = CameraPosition(
        target: LocationUtils.computeCentroid(markers.toList().map((e) => e.position)),
        tilt: 0,
        zoom: LocationUtils.getZoomLevelMini(users.map((e) => e.locationRadius!).reduce(max).toDouble())
    );

  }

  _snapCameraToMarkers() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(LocationUtils.generateBoundsFromMarkers(markers), 50));
  }

}