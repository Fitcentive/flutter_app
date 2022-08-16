import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/image_picker/custom_image_picker.dart';
import 'package:flutter_app/src/utils/dialog_utils.dart';
import 'package:image_cropper/image_cropper.dart';
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

    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarWidgetColor: Theme.of(context).primaryColor,
              initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );
      return Tuple2(await croppedFile?.readAsBytes(), image.name);
    }
    return Tuple2(await image?.readAsBytes(), image?.name);
  }

}

CustomImagePicker getImagePicker() => MobileImagePicker();
