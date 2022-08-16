import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ImageRepository {
  static const String BASE_URL = "https://api.vid.app/api/gateway/image/upload";

  Future<String> uploadImage(String filePath, Uint8List rawImage, String accessToken) async {
    var request = http.MultipartRequest('POST', Uri.parse("$BASE_URL/$filePath"))
      ..headers["Authorization"] = "Bearer $accessToken"
      ..files.add(http.MultipartFile.fromBytes("file", rawImage, filename: "file"));
    final response = await request.send();
    if (response.statusCode == HttpStatus.ok) {
      return filePath;
    } else {
      throw Exception("uploadImage: Received bad response with status: ${response.statusCode}");
    }
  }
}