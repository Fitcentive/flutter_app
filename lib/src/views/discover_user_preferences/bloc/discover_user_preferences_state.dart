import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DiscoverUserPreferencesState extends Equatable {
  const DiscoverUserPreferencesState();

  @override
  List<Object?> get props => [];
}

class DiscoverUserPreferencesStateInitial extends DiscoverUserPreferencesState {

  const DiscoverUserPreferencesStateInitial();
}

class UserDiscoverPreferencesModified extends DiscoverUserPreferencesState {
  final PublicUserProfile userProfile;

  final LatLng? locationCenter;
  final int? locationRadius;
  final String? preferredTransportMode;
  final List<String>? activitiesInterestedIn;
  final List<String>? fitnessGoals;
  final List<String>? desiredBodyTypes;
  final List<String>? gendersInterestedIn;
  final List<String>? preferredDays;
  final int? minimumAge;
  final int? maximumAge;
  final double? hoursPerWeek;
  final bool? hasGym;
  final String? gymLocationId;


  const UserDiscoverPreferencesModified({
    required this.userProfile,
    this.locationCenter,
    this.locationRadius,
    this.preferredTransportMode,
    this.hasGym,
    this.gymLocationId,
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
  ];
}

