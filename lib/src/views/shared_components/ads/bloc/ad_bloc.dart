import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_event.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class AdBloc extends Bloc<AdEvent, AdState> {
  final PublicGatewayRepository publicGatewayRepository;
  final FlutterSecureStorage secureStorage;

  Timer? _refreshAdTimer;

  final logger = Logger("AdBloc");

  AdBloc({
    required this.publicGatewayRepository,
    required this.secureStorage,
  }) : super(const InitialAdState()) {
    on<FetchNewAd>(_fetchNewAd);
    on<FetchAdUnitIds>(_fetchAdUnitIds);
    on<NoAdsRequiredAsUserIsPremium>(_noAdsRequiredAsUserIsPremium);
  }

  void dispose() {
    _refreshAdTimer?.cancel();
  }

  void _noAdsRequiredAsUserIsPremium(NoAdsRequiredAsUserIsPremium event, Emitter<AdState> emit) async {
    emit(const AdsDisabled());
  }

  void _fetchNewAd(FetchNewAd event, Emitter<AdState> emit) async {
    final currentState = state;
    if (currentState is AdUnitIdFetched) {
      emit(
          NewAdLoadRequested(
            adUnitId: currentState.adUnitId,
            randomId: StringUtils.generateRandomString(32)
          )
      );
      _refreshAdTimer = Timer(const Duration(seconds: AdUtils.adRefreshTimeInSeconds), () {
        add(const FetchNewAd());
      });
    }
    else if (currentState is NewAdLoadRequested) {
      emit(
          NewAdLoadRequested(
              adUnitId: currentState.adUnitId,
              randomId: StringUtils.generateRandomString(32)
          )
      );
      _refreshAdTimer = Timer(const Duration(seconds: AdUtils.adRefreshTimeInSeconds), () {
        add(const FetchNewAd());
      });
    }
  }

  void _fetchAdUnitIds(FetchAdUnitIds event, Emitter<AdState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final adUnitId = await publicGatewayRepository.getAdUnitId(
        kDebugMode, Platform.isAndroid, AdType.banner, accessToken!);
    emit(
        AdUnitIdFetched(
            adUnitId: adUnitId,
        )
    );
  }
}
