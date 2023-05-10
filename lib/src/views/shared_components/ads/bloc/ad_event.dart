import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/user_profile.dart';

abstract class AdEvent extends Equatable {
  const AdEvent();

  @override
  List<Object> get props => [];
}

class FetchAdUnitIds extends AdEvent {
  final UserProfile user;

  const FetchAdUnitIds({required this.user});

  @override
  List<Object> get props => [user];
}


class FetchNewAd extends AdEvent {
  final UserProfile user;

  const FetchNewAd({required this.user});

  @override
  List<Object> get props => [user];
}
