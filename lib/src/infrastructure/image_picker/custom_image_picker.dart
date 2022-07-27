import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'image_picker_stub.dart'
    if (dart.library.io) 'package:flutter_app/src/infrastructure/image_picker/mobile_image_picker.dart'
    if (dart.library.html) 'package:flutter_app/src/infrastructure/image_picker/web_image_picker.dart';

abstract class CustomImagePicker {

  Future<Tuple2<Uint8List?, String?>> pickImage(BuildContext context);

  factory CustomImagePicker() => getImagePicker();

}