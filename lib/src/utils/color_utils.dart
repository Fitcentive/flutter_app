import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ColorUtils {
  static const List<Color> circleColours = [
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.yellow,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.greenAccent
  ];

  static Map<Color, double> colorToHueMap = {
    Colors.teal: BitmapDescriptor.hueAzure,
    Colors.orange: BitmapDescriptor.hueOrange,
    Colors.blue: BitmapDescriptor.hueBlue,
    Colors.yellow: BitmapDescriptor.hueYellow,
    Colors.pinkAccent: BitmapDescriptor.hueRose,
    Colors.redAccent: BitmapDescriptor.hueRed,
    Colors.greenAccent: BitmapDescriptor.hueGreen,
  };
}