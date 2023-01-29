import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

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
  final DateTime? meetupTime;
  final String? meetupName;
  final String? locationId;
  final List<PublicUserProfile> participantUserProfiles;
  final List<MeetupAvailability> currentUserAvailabilities;

  const MeetupModified({
    this.meetupTime,
    this.meetupName,
    this.locationId,
    required this.participantUserProfiles,
    required this.currentUserAvailabilities,
  });

  @override
  List<Object?> get props => [
    meetupTime,
    meetupName,
    locationId,
    participantUserProfiles,
    currentUserAvailabilities,
  ];
}

