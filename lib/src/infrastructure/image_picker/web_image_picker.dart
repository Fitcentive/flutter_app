import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/image_picker/custom_image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:tuple/tuple.dart';

class WebImagePicker implements CustomImagePicker {

  @override
  Future<Tuple2<Uint8List?, String?>> pickImage(BuildContext context) async {
    final html.File? htmlFile = await ImagePickerWeb.getImageAsFile();
    final bytes = htmlFile != null ? await _getUint8ListFromHtmlFile(htmlFile) : null;
    return Tuple2(bytes, htmlFile?.name);
  }

  Future<Uint8List> _getUint8ListFromHtmlFile(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    return (reader.result as Uint8List);
  }

}

CustomImagePicker getImagePicker() => WebImagePicker();
