import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/ad_widget/ad_widget.dart';
import 'package:flutter_app/src/views/shared_components/ads/bottom_bar_ad_widget.dart';

class MobileAdWidget implements CustomAdWidget {

  MobileAdWidget();

  @override
  Widget render(BuildContext context, double maxHeight) {
    return BottomBarAdWidget(maxHeight: maxHeight);
  }
}

CustomAdWidget getAdWidget() => MobileAdWidget();