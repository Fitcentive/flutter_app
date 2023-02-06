import 'package:flutter/material.dart';

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
}