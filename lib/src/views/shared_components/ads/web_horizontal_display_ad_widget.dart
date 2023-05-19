import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_bloc.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_event.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

class WebHorizontalDisplayAdWidget extends StatefulWidget {
  final double maxHeight;

  const WebHorizontalDisplayAdWidget({
    super.key,
    required this.maxHeight
  });

  @override
  State createState() {
    return WebHorizontalDisplayAdWidgetState();
  }
}

class WebHorizontalDisplayAdWidgetState extends State<WebHorizontalDisplayAdWidget> {

  final logger = Logger("WebHorizontalDisplayAdWidgetState");

  late AdBloc _adBloc;
  bool initialLoad = true;

  Widget? webAd;

  @override
  void initState() {
    super.initState();

    _adBloc = BlocProvider.of<AdBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdBloc, AdState>(
      listener: (context, state) {
        if (state is NewAdLoadRequested) {
          setState(() {
            webAd = adsenseAdsView();
          });
        }
        else if (state is AdUnitIdFetched) {
          _adBloc.add(const FetchNewAd());
        }
      },
      child: BlocBuilder<AdBloc, AdState>(
        builder: (context, state) {
          if (state is NewAdLoadRequested) {
            if (initialLoad) {
              webAd = adsenseAdsView();
              initialLoad = false;
            }
            return Container(
              color: Colors.white,
              child: _displayAd(),
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            );
          }
        },
      ),
    );
  }

  _displayAd() {
    if (webAd != null) {
      return SizedBox(
        width: ScreenUtils.getScreenWidth(context),
        height: widget.maxHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: webAd!,
            ),
          ),
        ),
      );
    }
    else {
      return const Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Center(
            child:  CircularProgressIndicator(
              color: Colors.teal,
            ),
          ),
        ),
      );
    }
  }

  Widget adsenseAdsView() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        'adview_not_homepage',
            (int viewID) => html.IFrameElement()
          ..width = '320'
          ..height = '100'
          ..src = 'adview.html'
          ..style.width='100%'
          ..style.height='100%'
          // ..style.border = 'none'
          ..style.border = 'solid'
          ..style.borderColor = 'teal'
    );

    return SizedBox(
      height: 100,
      width: ScreenUtils.getScreenWidth(context),
      child: const Padding(
        padding: EdgeInsets.all(5.0),
        child: HtmlElementView(
          viewType: 'adview_not_homepage',
        ),
      ),
    );
  }

}