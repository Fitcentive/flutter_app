import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';

class ImageUtils {
  static const String imageBaseUrl = "${ConstantUtils.API_HOST_URL}/api/gateway/image";

  static DecorationImage? getUserProfileImage(PublicUserProfile? profile, int width, int height) {
    final photoUrlOpt = profile?.photoUrl;
    if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("$imageBaseUrl/$photoUrlOpt?transform=${width}x${height}"), fit: BoxFit.fitHeight);
    } else {
      return null;
    }
  }

  static getFullImageUrl(String? photoUrlOpt, int width, int height) =>
      "$imageBaseUrl/$photoUrlOpt?transform=${width}x${height}";

  static DecorationImage? getImage(String? photoUrlOpt, int width, int height) {
    if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("$imageBaseUrl/$photoUrlOpt?transform=${width}x${height}"), fit: BoxFit.fitHeight);
    } else {
      return null;
    }
  }
}