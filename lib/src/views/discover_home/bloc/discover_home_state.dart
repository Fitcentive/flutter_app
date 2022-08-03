import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';

abstract class DiscoverHomeState extends Equatable {
  const DiscoverHomeState();

  @override
  List<Object?> get props => [];
}

class DiscoverHomeStateInitial extends DiscoverHomeState {

  const DiscoverHomeStateInitial();
}

class DiscoverUserPreferencesFetched extends DiscoverHomeState {
  final UserDiscoveryPreferences? discoveryPreferences;
  final UserFitnessPreferences? fitnessPreferences;
  final UserPersonalPreferences? personalPreferences;


  const DiscoverUserPreferencesFetched({
    this.discoveryPreferences,
    this.fitnessPreferences,
    this.personalPreferences
  });

  @override
  List<Object?> get props => [discoveryPreferences, fitnessPreferences, personalPreferences];
}