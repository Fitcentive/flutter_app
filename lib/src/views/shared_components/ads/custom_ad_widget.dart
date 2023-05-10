import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_bloc.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_event.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class CustomAdWidget extends StatefulWidget {
  final double maxHeight;

  const CustomAdWidget({
    super.key,
    required this.maxHeight
  });

  @override
  State createState() {
    return CustomAdWidgetState();
  }
}

class CustomAdWidgetState extends State<CustomAdWidget> {

  final logger = Logger("CustomAdWidgetState");

  late AdBloc _adBloc;

  BannerAd? _bannerAd;

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
            _loadAd(state.adUnitId);
          });
        }
        else if (state is AdUnitIdFetched) {
          _adBloc.add(const FetchNewAd());
        }
      },
      child: Container(
        color: Colors.white,
        child: _displayAd(),
      ),
    );
  }

  _displayAd() {
    if (_bannerAd != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: SizedBox(
            width: max(_bannerAd!.size.width.toDouble(), ScreenUtils.getScreenWidth(context)),
            height: min(_bannerAd!.size.height.toDouble(), widget.maxHeight),
            child: AdWidget(ad: _bannerAd!),
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

  void _loadAd(String adUnitId) async {
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final AnchoredAdaptiveBannerAdSize? size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(context).size.width.truncate()
    );

    if (size == null) {
      logger.info('Unable to get height of anchored banner.');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          logger.info('$ad loaded: ${ad.responseInfo}');
          setState(() {
            // When the ad is loaded, get the ad size and use it to set
            // the height of the ad container.
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          logger.info('Anchored adaptive banner failedToLoad: $error');
          ad.dispose();
        },
      ),
    );
    return _bannerAd!.load();
  }

}