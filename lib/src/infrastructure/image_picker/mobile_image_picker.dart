import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/image_picker/custom_image_picker.dart';
import 'package:flutter_app/src/utils/dialog_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tuple/tuple.dart';

class MobileImagePicker implements CustomImagePicker {

  late ImagePicker _imagePicker;

  MobileImagePicker() {
    _imagePicker = ImagePicker();
  }

  @override
  Future<Tuple2<Uint8List?, String?>> pickImage(BuildContext context) async {
    final imageSource = await showDialog(context: context, builder: (context) {
      return DialogUtils.showImageSourceSimpleDialog(context);
    });
    final image = await _imagePicker.pickImage(source: imageSource);
    return Tuple2(await image?.readAsBytes(), image?.name);
  }

}

CustomImagePicker getImagePicker() => MobileImagePicker();
