import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/user_profile.dart';

abstract class AdState extends Equatable {
  const AdState();

  @override
  List<Object> get props => [];

}

class InitialAdState extends AdState {
  const InitialAdState();

  @override
  List<Object> get props => [];

}

class AdUnitIdFetched extends AdState {
  final String adUnitId;
  final UserProfile user;

  const AdUnitIdFetched({required this.adUnitId, required this.user});

  @override
  List<Object> get props => [adUnitId, user];

}

class NewAdLoadRequested extends AdState {
  final String adUnitId;
  final UserProfile user;
  // This is there to force a refresh/reload because between state changes nothing else changes
  final String randomId;

  const NewAdLoadRequested({
    required this.adUnitId,
    required this.user,
    required this.randomId,
  });

  @override
  List<Object> get props => [user, adUnitId, randomId];

}