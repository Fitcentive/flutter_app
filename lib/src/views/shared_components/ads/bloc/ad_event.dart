import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/user_profile.dart';

abstract class AdEvent extends Equatable {
  const AdEvent();

  @override
  List<Object> get props => [];
}

class FetchAdUnitIds extends AdEvent {

  const FetchAdUnitIds();

  @override
  List<Object> get props => [];
}


class FetchNewAd extends AdEvent {

  const FetchNewAd();

  @override
  List<Object> get props => [];
}

class NoAdsRequiredAsUserIsPremium extends AdEvent {

  const NoAdsRequiredAsUserIsPremium();

  @override
  List<Object> get props => [];
}
