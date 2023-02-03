import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';

abstract class DetailedMeetupEvent extends Equatable {
  const DetailedMeetupEvent();

  @override
  List<Object?> get props => [];
}

class FetchAdditionalMeetupData extends DetailedMeetupEvent {
  final String meetupId;
  final String? meetupLocationFsqId;
  final List<String> participantIds;

  const FetchAdditionalMeetupData({
    required this.meetupId,
    required this.participantIds,
    required this.meetupLocationFsqId
  });

  @override
  List<Object?> get props => [meetupId, participantIds, meetupLocationFsqId];
}


class SaveAvailabilitiesForCurrentUser extends DetailedMeetupEvent {
  final String currentUserId;
  final String meetupId;
  final List<MeetupAvailabilityUpsert> availabilities;

  const SaveAvailabilitiesForCurrentUser({
    required this.meetupId,
    required this.currentUserId,
    required this.availabilities
  });

  @override
  List<Object?> get props => [meetupId, currentUserId, availabilities];
}

class UpdateMeetupDetails extends DetailedMeetupEvent {
  final String meetupId;
  final DateTime? meetupTime;
  final String? meetupName;
  final Location? location;
  final List<String> meetupParticipantUserIds;


  const UpdateMeetupDetails({
    required this.meetupId,
    required this.meetupTime,
    required this.meetupName,
    required this.location,
    required this.meetupParticipantUserIds
  });

  @override
  List<Object?> get props => [
    meetupId,
    meetupTime,
    meetupName,
    location,
    meetupParticipantUserIds,
  ];
}

class AddParticipantDecisionToMeetup extends DetailedMeetupEvent {
  final String meetupId;
  final String participantId;
  final bool hasAccepted;


  const AddParticipantDecisionToMeetup({
    required this.meetupId,
    required this.participantId,
    required this.hasAccepted
  });

  @override
  List<Object?> get props => [
    meetupId,
    participantId,
    hasAccepted
  ];
}