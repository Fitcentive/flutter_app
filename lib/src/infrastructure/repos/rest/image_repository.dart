import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class ImageRepository {
  static const String BASE_URL = "https://api.vid.app/api/gateway/image/upload";

  CompressFormat _getFormat(String filePath) {
    final extension = filePath.split(".").last;
    switch (extension) {
      case "jpg": return CompressFormat.jpeg;
      case "jpeg": return CompressFormat.jpeg;
      case "png": return CompressFormat.png;
      case "heic": return CompressFormat.heic;
      case "webp": return CompressFormat.webp;
      default: return CompressFormat.jpeg;
    }
  }

  Future<String> uploadImage(String filePath, Uint8List rawImage, String accessToken) async {
    // Compression only on mobile for now
    final Uint8List compressedImage;
    if (DeviceUtils.isMobileDevice()) {
      compressedImage = await FlutterImageCompress.compressWithList(rawImage, format: _getFormat(filePath), quality: 50);
    }
    else {
      compressedImage = rawImage;
    }

    var request = http.MultipartRequest('POST', Uri.parse("$BASE_URL/$filePath"))
      ..headers["Authorization"] = "Bearer $accessToken"
      ..files.add(http.MultipartFile.fromBytes("file", compressedImage, filename: "file"));
    final response = await request.send();
    if (response.statusCode == HttpStatus.ok) {
      return filePath;
    } else {
      throw Exception("uploadImage: Received bad response with status: ${response.statusCode}");
    }
  }
}