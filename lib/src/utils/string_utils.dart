import 'package:flutter_app/src/models/public_user_profile.dart';

class StringUtils {

  static String getUserNameFromUserId(PublicUserProfile? publicUserProfile) {
    if (publicUserProfile != null) {
      return "${publicUserProfile.firstName} ${publicUserProfile.lastName}";
    }
    return "";
  }

  static getNumberOfLikesOnPostText(String currentUserId, List<String> likedUserIds) {
    if (likedUserIds.isEmpty) {
      return "Nobody likes this";
    }
    if (likedUserIds.length == 1) {
      if (likedUserIds.first == currentUserId) {
        return "You like this!";
      }
      else {
        return "1 person likes this!";
      }
    }
    else if (likedUserIds.length == 2 && likedUserIds.contains(currentUserId)) {
      return "You and ${likedUserIds.length - 1} person like this!";
    }
    else {
      if (likedUserIds.contains(currentUserId)) {
        return "You and ${likedUserIds.length - 1} people like this!";
      }
      else {
        return "${likedUserIds.length} people like this!";
      }
    }
  }
}