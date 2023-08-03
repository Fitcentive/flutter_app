import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ColorUtils {

  static const Map<String, Color> meetupStatusToColorMap = {
    "Unscheduled": Colors.redAccent,
    "Unconfirmed": Colors.amber,
    "Confirmed"  : Colors.teal,
    "Complete"   : Colors.blue,
    "Expired"    : Colors.grey
  };

  static const List<Color> circleColours = [
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.yellow,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.deepPurple,
  ];

  static const List<Color> circleColoursWithoutTeal = [
    Colors.orange,
    Colors.blue,
    Colors.yellow,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.deepPurple,
  ];

  static final List<BitmapDescriptor> markerList = [
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
    BitmapDescriptor.defaultMarker,
  ];

  static const MaterialColor BUTTON_AVAILABLE = Colors.teal;
  static const MaterialColor BUTTON_DISABLED = Colors.grey;
  static const MaterialColor BUTTON_DANGER = Colors.red;

  static const Color SPLASH_SCREEN_ICON_BACKGROUND_COLOR = Color(0xffE9FCE4);
}