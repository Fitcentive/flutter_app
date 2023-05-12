import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/home_page_ad_widget/home_page_ad_widget.dart';
import 'package:flutter_app/src/views/shared_components/ads/home_page_ad_widget.dart';

class MobileHomePageAdWidget implements CustomHomePageAdWidget {

  MobileHomePageAdWidget();

  @override
  Widget render(BuildContext context, double maxHeight) {
    return HomePageAdWidget(maxHeight: maxHeight);
  }
}

CustomHomePageAdWidget getAdWidget() => MobileHomePageAdWidget();
