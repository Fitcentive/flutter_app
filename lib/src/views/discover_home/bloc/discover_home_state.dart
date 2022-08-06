import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
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
  final List<PublicUserProfile> discoveredUserProfiles;


  const DiscoverUserDataFetched({
    this.discoveryPreferences,
    this.fitnessPreferences,
    this.personalPreferences,
    required this.discoveredUserProfiles,
  });

  @override
  List<Object?> get props => [discoveryPreferences, fitnessPreferences, personalPreferences, discoveredUserProfiles];
}