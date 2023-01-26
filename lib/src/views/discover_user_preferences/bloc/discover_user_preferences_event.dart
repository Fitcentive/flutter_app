import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_gym_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DiscoverUserPreferencesEvent extends Equatable {
  const DiscoverUserPreferencesEvent();

  @override
  List<Object?> get props => [];
}

class DiscoverUserPreferencesInitial extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;
  final UserDiscoveryPreferences? discoveryPreferences;
  final UserFitnessPreferences? fitnessPreferences;
  final UserPersonalPreferences? personalPreferences;
  final UserGymPreferences? gymPreferences;


  const DiscoverUserPreferencesInitial({
    required this.userProfile,
    this.discoveryPreferences,
    this.fitnessPreferences,
    this.personalPreferences,
    this.gymPreferences
  });

  @override
  List<Object?> get props => [
    userProfile,
    discoveryPreferences,
    fitnessPreferences,
    personalPreferences,
    gymPreferences,
  ];
}

// Generic event used for all preference changes
// Widget is responsible for not overwriting state and maintaining its own fields
class UserDiscoverPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final LatLng? locationCenter;
  final int? locationRadius;
  final String? preferredTransportMode;
  final bool? hasGym;
  final String? gymLocationId;
  final String? gymLocationFsqId;
  final List<String>? activitiesInterestedIn;
  final List<String>? fitnessGoals;
  final List<String>? desiredBodyTypes;
  final List<String>? gendersInterestedIn;
  final List<String>? preferredDays;
  final int? minimumAge;
  final int? maximumAge;
  final double? hoursPerWeek;

  const UserDiscoverPreferencesChanged({
    required this.userProfile,
    this.locationCenter,
    this.locationRadius,
    this.preferredTransportMode,
    this.hasGym,
    this.gymLocationId,
    this.gymLocationFsqId,
    this.activitiesInterestedIn,
    this.fitnessGoals,
    this.desiredBodyTypes,
    this.gendersInterestedIn,
    this.preferredDays,
    this.minimumAge,
    this.maximumAge,
    this.hoursPerWeek
  });

  @override
  List<Object?> get props => [
    locationCenter,
    locationRadius,
    preferredTransportMode,
    activitiesInterestedIn,
    fitnessGoals,
    desiredBodyTypes,
    gendersInterestedIn,
    preferredDays,
    minimumAge,
    maximumAge,
    hoursPerWeek,
    hasGym,
    gymLocationId,
    gymLocationFsqId,
  ];
}

class UserDiscoverLocationPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final LatLng locationCenter;
  final int locationRadius;

  const UserDiscoverLocationPreferencesChanged({
    required this.userProfile,
    required this.locationCenter,
    required this.locationRadius
  });

  @override
  List<Object?> get props => [
    userProfile,
    locationCenter,
    locationRadius,
  ];
}

class UserDiscoverPreferredTransportModePreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final String preferredTransportMode;

  const UserDiscoverPreferredTransportModePreferencesChanged({
    required this.userProfile,
    required this.preferredTransportMode,
  });

  @override
  List<Object?> get props => [
    userProfile,
    preferredTransportMode,
  ];
}

class UserDiscoverActivityPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final List<String> activitiesInterestedIn;

  const UserDiscoverActivityPreferencesChanged({
    required this.userProfile,
    required this.activitiesInterestedIn,
  });

  @override
  List<Object?> get props => [
    userProfile,
    activitiesInterestedIn,
  ];
}

class UserDiscoverFitnessGoalsPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final List<String> fitnessGoals;

  const UserDiscoverFitnessGoalsPreferencesChanged({
    required this.userProfile,
    required this.fitnessGoals,
  });

  @override
  List<Object?> get props => [
    userProfile,
    fitnessGoals,
  ];
}

class UserDiscoverBodyTypePreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final List<String> desiredBodyTypes;

  const UserDiscoverBodyTypePreferencesChanged({
    required this.userProfile,
    required this.desiredBodyTypes,
  });

  @override
  List<Object?> get props => [
    userProfile,
    desiredBodyTypes,
  ];
}

class UserDiscoverGenderPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final List<String> gendersInterestedIn;
  final int minimumAge;
  final int maximumAge;

  const UserDiscoverGenderPreferencesChanged({
    required this.userProfile,
    required this.gendersInterestedIn,
    required this.minimumAge,
    required this.maximumAge,
  });

  @override
  List<Object?> get props => [
    userProfile,
    gendersInterestedIn,
    minimumAge,
    maximumAge,
  ];
}

class UserDiscoverDayPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final List<String> preferredDays;
  final double hoursPerWeek;

  const UserDiscoverDayPreferencesChanged({
    required this.userProfile,
    required this.preferredDays,
    required this.hoursPerWeek,
  });

  @override
  List<Object?> get props => [
    userProfile,
    preferredDays,
    hoursPerWeek
  ];
}


class UserDiscoverGymPreferencesChanged extends DiscoverUserPreferencesEvent {
  final PublicUserProfile userProfile;

  final String? gymLocationId;
  final String? gymLocationFsqId;
  final bool hasGym;

  const UserDiscoverGymPreferencesChanged({
    required this.userProfile,
    required this.hasGym,
    this.gymLocationId,
    this.gymLocationFsqId,
  });

  @override
  List<Object?> get props => [
    userProfile,
    gymLocationId,
    gymLocationFsqId,
    hasGym,
  ];
}