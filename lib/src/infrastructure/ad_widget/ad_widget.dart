import 'package:flutter/material.dart';

import 'ad_widget_stub.dart'
  if (dart.library.io) 'package:flutter_app/src/infrastructure/ad_widget/mobile_ad_widget.dart'
  if (dart.library.html) 'package:flutter_app/src/infrastructure/ad_widget/web_ad_widget.dart';

abstract class CustomAdWidget {

  Widget render(BuildContext context, double maxHeight);

  factory CustomAdWidget() => getAdWidget();

}