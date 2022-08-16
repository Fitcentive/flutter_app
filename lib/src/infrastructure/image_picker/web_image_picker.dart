import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/image_picker/custom_image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart' as universal;

class WebImagePicker implements CustomImagePicker {

  universal.File createFileFromBytes(Uint8List bytes) => universal.File.fromRawPath(bytes);


  @override
  Future<Tuple2<Uint8List?, String?>> pickImage(BuildContext context) async {
    final html.File? htmlFile = await ImagePickerWeb.getImageAsFile();

    // There is an error in creating temp file out of bytes, refer to stackoverflow post
    // https://stackoverflow.com/questions/71321583/convert-uinit8list-to-file-in-flutter-web
    // if (htmlFile != null) {
    //   final bytes = await _getUint8ListFromHtmlFile(htmlFile);
    //   final webFile = createFileFromBytes(bytes);
    //
    //   CroppedFile? croppedFile = await ImageCropper().cropImage(
    //     sourcePath: webFile.path,
    //     aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    //     aspectRatioPresets: [
    //       CropAspectRatioPreset.square,
    //     ],
    //     uiSettings: [
    //       AndroidUiSettings(
    //         toolbarTitle: 'Cropper',
    //         toolbarWidgetColor: Theme.of(context).primaryColor,
    //         initAspectRatio: CropAspectRatioPreset.original,
    //       ),
    //       IOSUiSettings(
    //         title: 'Cropper',
    //       ),
    //       WebUiSettings(
    //         context: context,
    //       ),
    //     ],
    //   );
    //   return Tuple2(await croppedFile?.readAsBytes(), htmlFile.name);
    // }

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
