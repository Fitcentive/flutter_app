import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DialogUtils {
  static showImageSourceSimpleDialog(BuildContext context) {
    return SimpleDialog(
      title: const Text("Select image source"),
      children: [
        SimpleDialogOption(
          child: const Text("Gallery"),
          onPressed: () {
            Navigator.pop(context, ImageSource.gallery);
          },
        ),
        SimpleDialogOption(
          child: const Text("Camera"),
          onPressed: () {
            Navigator.pop(context, ImageSource.camera);
          },
        ),
      ],
    );
  }
}