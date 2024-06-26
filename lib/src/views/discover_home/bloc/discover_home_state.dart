import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_gym_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoverHomeState extends Equatable {
  const DiscoverHomeState();

  @override
  List<Object?> get props => [];
}

class DiscoverHomeStateInitial extends DiscoverHomeState {

  const DiscoverHomeStateInitial();
}

class DiscoverUserDataFetched extends DiscoverHomeState {
  final UserDiscoveryPreferences? discoveryPreferences;
  final UserFitnessPreferences? fitnessPreferences;
  final UserPersonalPreferences? personalPreferences;
  final UserGymPreferences? gymPreferences;
  final List<PublicUserProfile> discoveredUserProfiles;
  final bool doesNextPageExist;

  const DiscoverUserDataFetched({
    this.discoveryPreferences,
    this.fitnessPreferences,
    this.personalPreferences,
    this.gymPreferences,
    required this.discoveredUserProfiles,
    required this.doesNextPageExist,
  });

  @override
  List<Object?> get props => [
    discoveryPreferences,
    fitnessPreferences,
    personalPreferences,
    gymPreferences,
    discoveredUserProfiles,
    doesNextPageExist
  ];
}