import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
              GoogleMap(
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
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(2),
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
              )
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


  Future<int> _setupMapIconsForUsers(List<PublicUserProfile> users) async {
    _setupColorsForUsers(users);

    for (var e in users) {
      if (userIdToMapMarkerIcon[e.userId] == null) {
        userIdToMapMarkerIcon[e.userId] = await _generateCustomMarkerForUser(e);
      }
    }

    final Uint8List? gymMarkerIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon.png', 100);
    customGymLocationIcon = BitmapDescriptor.fromBytes(gymMarkerIcon!);

    return 1;
  }

  // todo - infinite loop if too many users!!!
  _setupColorsForUsers(List<PublicUserProfile> users) {
    users.forEach((u) {
      var nextColor = userIdToMapMarkerColor[u.userId];

      if (nextColor == null) {
        // We always give same colour to current user for consistency
        if (u.userId == widget.currentUserProfile.userId) {
          userIdToMapMarkerColor[u.userId] = Colors.teal;
          usedColoursThusFar.add(Colors.teal);
        }

        else {
          final _random = Random();
          var nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
          while (usedColoursThusFar.contains(nextColour)) {
            nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
          }

          userIdToMapMarkerColor[u.userId] = nextColour;
          usedColoursThusFar.add(nextColour);
        }
      }
    });
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