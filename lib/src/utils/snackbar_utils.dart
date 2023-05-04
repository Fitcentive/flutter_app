import 'package:flutter/material.dart';

class SnackbarUtils {

  static const Duration shortDuration = Duration(milliseconds: 1500);

  static void showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static void showSnackBarShort(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: shortDuration,));
  }
}