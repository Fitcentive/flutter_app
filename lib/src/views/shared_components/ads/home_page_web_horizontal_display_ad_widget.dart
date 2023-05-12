import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_bloc.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_event.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

class HomePageWebHorizontalDisplayAdWidget extends StatefulWidget {
  final double maxHeight;

  const HomePageWebHorizontalDisplayAdWidget({
    super.key,
    required this.maxHeight
  });

  @override
  State createState() {
    return HomePageWebHorizontalDisplayAdWidgetState();
  }
}

class HomePageWebHorizontalDisplayAdWidgetState extends State<HomePageWebHorizontalDisplayAdWidget> {

  final logger = Logger("HomePageWebHorizontalDisplayAdWidgetState");

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
            return const CircularProgressIndicator(
              color: Colors.teal,
            );
          }
        },
      ),
    );
  }

  _displayAd() {
    if (webAd != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: webAd!,
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
        'adview',
            (int viewID) => html.IFrameElement()
          ..width = '320'
          ..height = '100'
          ..src = 'adview.html'
          ..style.border = 'none'
          // ..style.border = 'solid'
    );

    return SizedBox(
      height: 100,
      width: ScreenUtils.getScreenWidth(context),
      child: const HtmlElementView(
        viewType: 'adview',
      ),
    );
  }

}