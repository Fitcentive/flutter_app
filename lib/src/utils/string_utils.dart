import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.isEmpty ? "" : (newValue.text.length == 1 ? "${newValue.text[0].toUpperCase()}" : "${newValue.text[0].toUpperCase()}${newValue.text.substring(1)}"),
      selection: newValue.selection,
    );
  }
}

class StringUtils {

  static String truncateLongString(String s) {
    if (s.length <= 40) {
      return s;
    }
    else {
      return "${s.substring(0, min(50, s.length))}...";
    }
  }

  static String truncateLongStringWithLimit(String s, int limit) {
    if (s.length <= limit) {
      return s;
    }
    else {
      return "${s.substring(0, min(limit, s.length))}...";
    }
  }

  static String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(List.generate(len, (index) => r.nextInt(33) + 89));
  }

  static String getUserNameFromUserProfile(PublicUserProfile? publicUserProfile) {
    if (publicUserProfile != null) {
      return "${publicUserProfile.firstName} ${publicUserProfile.lastName}";
    }
    return "Deleted User";
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