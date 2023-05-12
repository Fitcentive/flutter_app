import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/home_page_ad_widget/home_page_ad_widget.dart';
import 'package:flutter_app/src/views/shared_components/ads/home_page_web_horizontal_display_ad_widget.dart';

class WebHomePageAdWidget implements CustomHomePageAdWidget {

  WebHomePageAdWidget();

  @override
  Widget render(BuildContext context, double maxHeight) {
    return HomePageWebHorizontalDisplayAdWidget(maxHeight: maxHeight);
  }
}

CustomHomePageAdWidget getAdWidget() => WebHomePageAdWidget();