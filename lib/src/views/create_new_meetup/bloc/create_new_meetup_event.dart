import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class CreateNewMeetupEvent extends Equatable {
  const CreateNewMeetupEvent();

  @override
  List<Object?> get props => [];
}

class NewMeetupChanged extends CreateNewMeetupEvent {
  final PublicUserProfile currentUserProfile;
  final DateTime? meetupTime;
  final String? meetupName;
  final Location? location;
  final List<String> meetupParticipantUserIds;

  final List<List<bool>> currentUserAvailabilities;

  const NewMeetupChanged({
    required this.currentUserProfile,
    this.meetupTime,
    this.meetupName,
    this.location,
    required this.meetupParticipantUserIds,
    required this.currentUserAvailabilities
  });

  @override
  List<Object?> get props => [
    currentUserProfile,
    meetupTime,
    meetupName,
    location,
    meetupParticipantUserIds,
    currentUserAvailabilities
  ];
}

class SaveNewMeetup extends CreateNewMeetupEvent {
  final PublicUserProfile currentUserProfile;
  final DateTime? meetupTime;
  final String? meetupName;
  final Location? location;
  final List<String> meetupParticipantUserIds;

  final List<List<bool>> currentUserAvailabilities;

  const SaveNewMeetup({
    required this.currentUserProfile,
    this.meetupTime,
    this.meetupName,
    this.location,
    required this.meetupParticipantUserIds,
    required this.currentUserAvailabilities
  });

  @override
  List<Object?> get props => [
    currentUserProfile,
    meetupTime,
    meetupName,
    location,
    meetupParticipantUserIds,
    currentUserAvailabilities
  ];
}

class TrackAttemptToCreateMeetupEvent extends CreateNewMeetupEvent {

  const TrackAttemptToCreateMeetupEvent();

  @override
  List<Object?> get props => [];

}

