import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';

abstract class CreateNewMeetupState extends Equatable {
  const CreateNewMeetupState();

  @override
  List<Object?> get props => [];
}

class NewMeetupStateInitial extends CreateNewMeetupState {
  const NewMeetupStateInitial();

  @override
  List<Object?> get props => [];
}

class MeetupModified extends CreateNewMeetupState {
  final DateTime? meetupTime;
  final String? meetupName;
  final String? locationId;
  final List<String>? meetupParticipants;
  final List<MeetupAvailability> currentUserAvailabilities;

  const MeetupModified(
      this.meetupTime,
      this.meetupName,
      this.locationId,
      this.meetupParticipants,
      this.currentUserAvailabilities
  );

  @override
  List<Object?> get props => [
    meetupTime,
    meetupName,
    locationId,
    meetupParticipants,
    currentUserAvailabilities
  ];
}

