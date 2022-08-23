import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceUtils {
  static bool isMobileDevice() {
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
      return true;
    }
    return false;
  }

  static bool isDarkMode(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return isDarkMode;
  }
}