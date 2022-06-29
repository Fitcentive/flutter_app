import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:image_picker/image_picker.dart';

class ImageRepository {
  static const String BASE_URL = "http://api.vid.app/api/gateway/image/upload";

  Future<String> uploadImage(String filePath, XFile image, String accessToken) async {
    final dir = await path_provider.getTemporaryDirectory();
    File newFile = _createFile("${dir.absolute.path}/$filePath");
    final File? compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      newFile.path,
      quality: 50,
    );
    var request = http.MultipartRequest('POST', Uri.parse("$BASE_URL/$filePath"))
      ..headers["Authorization"] = "Bearer $accessToken"
      ..files.add(await http.MultipartFile.fromPath("file", compressedFile?.path ?? image.path));
    final response = await request.send();
    if (response.statusCode == HttpStatus.ok) {
      return filePath;
    } else {
      throw Exception("uploadImage: Received bad response with status: ${response.statusCode}");
    }
  }

  File _createFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }

}