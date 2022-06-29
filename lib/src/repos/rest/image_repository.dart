import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageRepository {
  static const String BASE_URL = "http://api.vid.app/api/upload/image/files";

  Future<String> uploadImage(String filePath, XFile image, String accessToken) async {
    var request = http.MultipartRequest('PUT', Uri.parse("$BASE_URL/$filePath"))
      ..headers["Authorization"] = "Bearer $accessToken"
      ..files.add(await http.MultipartFile.fromPath("file", image.path));
    final response = await request.send();
    if (response.statusCode == HttpStatus.ok) {
      return filePath;
    } else {
      throw Exception("uploadImage: Received bad response with status: ${response.statusCode}");
    }
  }

}