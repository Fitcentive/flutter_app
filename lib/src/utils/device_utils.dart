import 'package:flutter/foundation.dart';

class DeviceUtils {
  static bool isMobileDevice() {
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
      return true;
    }
    return false;
  }
}