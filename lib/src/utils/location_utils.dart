import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class LocationUtils {
  static const defaultLocation = LatLng(43.6777, -79.6248);
  static const defaultRadius = 1000; // metres

  static double getZoomLevel(double radius) {
    double zoomLevel = 11;
    if (radius > 0) {
      double radiusElevated = radius + radius / 2;
      double scale = radiusElevated / 500;
      zoomLevel = 16 - math.log(scale) / math.log(2);
    }
    zoomLevel = double.parse(zoomLevel.toStringAsFixed(2));
    return zoomLevel;
  }
}