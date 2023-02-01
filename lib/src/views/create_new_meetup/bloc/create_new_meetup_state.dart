import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class CreateNewMeetupState extends Equatable {
  const CreateNewMeetupState();

  @override
  List<Object?> get props => [];
}

class CreateNewMeetupStateInitial extends CreateNewMeetupState {
  const CreateNewMeetupStateInitial();

  @override
  List<Object?> get props => [];
}

class MeetupModified extends CreateNewMeetupState {
  final PublicUserProfile currentUserProfile;
  final DateTime? meetupTime;
  final String? meetupName;
  final Location? location;
  final List<PublicUserProfile> participantUserProfiles;

  // mxn matrix of booleans
  // m refers to days (0 indexed)
  // n refers to discrete time intervals per day == 46
  final List<List<bool>> currentUserAvailabilities;

  final Map<String, BitmapDescriptor> userIdToMapMarkerIconSet;
  final Map<String, Color> userIdToColorSet;

  const MeetupModified({
    required this.currentUserProfile,
    this.meetupTime,
    this.meetupName,
    this.location,
    required this.participantUserProfiles,
    required this.currentUserAvailabilities,
    required this.userIdToMapMarkerIconSet,
    required this.userIdToColorSet,
  });

  @override
  List<Object?> get props => [
    currentUserProfile,
    meetupTime,
    meetupName,
    location,
    participantUserProfiles,
    currentUserAvailabilities,
    userIdToMapMarkerIconSet,
    userIdToColorSet,
  ];
}

