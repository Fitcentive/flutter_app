import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/image_utils.dart';

class WidgetUtils {
  static Widget spacer(double allPadding) => Padding(padding: EdgeInsets.all(allPadding));

  static List<T> skipNulls<T>(List<T?> items) {
    return items.whereType<T>().toList();
  }

  static Widget? generatePostImageIfExists(String? postImageUrl) {
    if (postImageUrl != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          image: ImageUtils.getImage(postImageUrl, 300, 300),
        ),
      );
    }
    return null;
  }
}