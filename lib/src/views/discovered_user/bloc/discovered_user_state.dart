import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoveredUserState extends Equatable {
  const DiscoveredUserState();

  @override
  List<Object?> get props => [];
}

class DiscoveredUserStateInitial extends DiscoveredUserState {
  const DiscoveredUserStateInitial();
}

class DiscoveredUserDataLoading extends DiscoveredUserState {
  const DiscoveredUserDataLoading();
}

class DiscoveredUserPreferencesFetched extends DiscoveredUserState {
  final UserDiscoveryPreferences? discoveryPreferences;
  final UserFitnessPreferences? fitnessPreferences;
  final UserPersonalPreferences? personalPreferences;
  final PublicUserProfile otherUserProfile;
  final num discoverScore;

  const DiscoveredUserPreferencesFetched({
    this.discoveryPreferences,
    this.fitnessPreferences,
    this.personalPreferences,
    required this.otherUserProfile,
    required this.discoverScore,
  });

  @override
  List<Object?> get props => [
    discoveryPreferences,
    fitnessPreferences,
    personalPreferences,
    otherUserProfile,
    discoverScore
  ];
}
