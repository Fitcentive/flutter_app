import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceUtils {
  static bool isMobileDevice() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
      return true;
    }
    return false;
  }

  // NOTE: https://github.com/flutter/flutter/issues/87917
  // Because of this, mobile-(web) app has only default markers
  static bool isAppRunningOnMobileBrowser() {
    return kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  }

  static bool isDarkMode(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return isDarkMode;
  }
}