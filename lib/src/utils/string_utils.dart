import 'package:flutter_app/src/models/public_user_profile.dart';

class StringUtils {

  static String getUserNameFromUserId(String userId, PublicUserProfile? publicUserProfile) {
    if (publicUserProfile != null) {
      return "${publicUserProfile.firstName} ${publicUserProfile.lastName}";
    }
    return "";
  }
}