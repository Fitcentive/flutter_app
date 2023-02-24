import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/models/exercise/exercise_image.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ImageUtils {
  static const String imageBaseUrl = "${ConstantUtils.API_HOST_URL}/api/gateway/image";

  static DecorationImage? getExerciseImage(List<ExerciseImage> exerciseImages) {
    if (exerciseImages.isNotEmpty) {
      return DecorationImage(
          image: NetworkImage(exerciseImages.first.image), fit: BoxFit.fitHeight);
    } else {
      return const DecorationImage(
          image: AssetImage("assets/images/deleted_user_avatar.png")
      );
    }
  }

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

  // Inspired from https://stackoverflow.com/questions/67585895/how-do-we-create-custom-marker-icon-in-google-map-flutter
  static Future<BitmapDescriptor> getMarkerIcon(Uint8List imgList, Size size, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Radius radius = Radius.circular(size.width / 2);

    final Paint shadowPaint = Paint()..color = Colors.white;
    const double shadowWidth = 2.0;

    final Paint borderPaint = Paint()..color = color;
    const double borderWidth = 5.0;

    const double imageOffset = shadowWidth + borderWidth;

    // Add shadow circle
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0.0, 0.0, size.width, size.height),
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        ),
        shadowPaint);

    // Add border circle
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
              shadowWidth, shadowWidth, size.width - (shadowWidth * 2), size.height - (shadowWidth * 2)),
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        ),
        borderPaint);

    // Oval for the image
    Rect oval = Rect.fromLTWH(imageOffset, imageOffset,
        size.width - (imageOffset * 2), size.height - (imageOffset * 2));

    // Add path for oval image
    canvas.clipPath(Path()..addOval(oval));

    // Add image
    ui.Image image = await _loadImage(imgList); // Alternatively use your own method to get the image
    paintImage(canvas: canvas, image: image, rect: oval, fit: BoxFit.fitWidth);

    // Convert canvas to image
    final ui.Image markerAsImage =
    await pictureRecorder.endRecording().toImage(size.width.toInt(), size.height.toInt());

    // Convert image to bytes
    final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  static Future<ui.Image> _loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}