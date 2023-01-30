import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';

abstract class CreateNewMeetupEvent extends Equatable {
  const CreateNewMeetupEvent();

  @override
  List<Object?> get props => [];
}

class NewMeetupChanged extends CreateNewMeetupEvent {
  final DateTime? meetupTime;
  final String? meetupName;
  final String? locationId;
  final String? fsqLocationId;
  final List<String> meetupParticipantUserIds;
  final List<MeetupAvailability> currentUserAvailabilities;

  const NewMeetupChanged({
    this.meetupTime,
    this.meetupName,
    this.locationId,
    this.fsqLocationId,
    required this.meetupParticipantUserIds,
    required this.currentUserAvailabilities
  });

  @override
  List<Object?> get props => [
    meetupTime,
    meetupName,
    locationId,
    fsqLocationId,
    meetupParticipantUserIds,
    currentUserAvailabilities
  ];
}

