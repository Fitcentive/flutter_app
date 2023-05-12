import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/ad_widget/ad_widget.dart';
import 'package:flutter_app/src/views/shared_components/ads/web_horizontal_display_ad_widget.dart';

class WebAdWidget implements CustomAdWidget {

  WebAdWidget();

  @override
  Widget render(BuildContext context, double maxHeight) {
    return WebHorizontalDisplayAdWidget(maxHeight: maxHeight);
  }
}

CustomAdWidget getAdWidget() => WebAdWidget();