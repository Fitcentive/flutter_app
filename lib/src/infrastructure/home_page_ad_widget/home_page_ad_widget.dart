import 'package:flutter/material.dart';

import 'home_page_ad_widget_stub.dart'
  if (dart.library.io) 'package:flutter_app/src/infrastructure/home_page_ad_widget/mobile_home_page_ad_widget.dart'
  if (dart.library.html) 'package:flutter_app/src/infrastructure/home_page_ad_widget/web_home_page_ad_widget.dart';

abstract class CustomHomePageAdWidget {

  Widget render(BuildContext context, double maxHeight);

  factory CustomHomePageAdWidget() => getAdWidget();

}