import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      return const DecorationImage(
          image: AssetImage("assets/images/deleted_user_avatar.png")
      );
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

  static Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
  }
}