import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceUtils {

  /// Returns one of three values
  /// 1. iOS
  /// 2. Android
  /// 3. Web
  static String getEventPlatformForEventTracking() {
    if (DeviceUtils.isMobileDevice()) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return "iOS";
      }
      else {
        return "Android";
      }
    }
    else {
      return "Web";
    }
  }

  static bool isMobileDevice() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
      return true;
    }
    return false;
  }

  static bool isIOS() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }
    return false;
  }

  static bool isAndroid() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
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