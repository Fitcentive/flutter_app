import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile.dart';

class ImageUtils {
  static const String imageBaseUrl = "http://api.vid.app/api/gateway/image";

  static DecorationImage? getUserProfileImage(PublicUserProfile? profile, int width, int height) {
    final photoUrlOpt = profile?.photoUrl;
    if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("$imageBaseUrl/$photoUrlOpt?transform=${width}x${height}"), fit: BoxFit.fitHeight);
    } else {
      return null;
    }
  }

  static DecorationImage? getImage(String? photoUrlOpt, int width, int height) {
    if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("$imageBaseUrl/$photoUrlOpt?transform=${width}x${height}"), fit: BoxFit.fitHeight);
    } else {
      return null;
    }
  }
}