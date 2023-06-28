import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DetailedMeetupEvent extends Equatable {
  const DetailedMeetupEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllMeetupData extends DetailedMeetupEvent {
  final String meetupId;

  const FetchAllMeetupData({
    required this.meetupId,
  });

  @override
  List<Object?> get props => [meetupId];
}

class FetchAdditionalMeetupData extends DetailedMeetupEvent {
  final String meetupId;
  final String? meetupLocationFsqId;
  final List<String> participantIds;

  // These guys are provided by the widget itself
  final Meetup meetup;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;
  final List<PublicUserProfile> userProfiles;

  const FetchAdditionalMeetupData({
    required this.meetupId,
    required this.participantIds,
    required this.meetupLocationFsqId,
    required this.meetup,
    required this.participants,
    required this.decisions,
    required this.userProfiles,
  });

  @override
  List<Object?> get props => [
    meetupId,
    participantIds,
    meetupLocationFsqId,
    meetup,
    participants,
    decisions,
    userProfiles,
  ];
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

// This is used when meetup has < 3 participants
class GetDirectMessagePrivateChatRoomForMeetup extends DetailedMeetupEvent {
  final Meetup meetup;
  final String currentUserProfileId;
  final List<String> participants;

  const GetDirectMessagePrivateChatRoomForMeetup({
    required this.meetup,
    required this.currentUserProfileId,
    required this.participants
  });

  @override
  List<Object?> get props => [meetup, currentUserProfileId, participants];
}

class CreateChatRoomForMeetup extends DetailedMeetupEvent {
  final Meetup meetup;
  final String roomName;
  final List<String> participants;

  const CreateChatRoomForMeetup({
    required this.meetup,
    required this.roomName,
    required this.participants
  });

  @override
  List<Object?> get props => [meetup, roomName, participants];
}

class DeleteMeetupForUser extends DetailedMeetupEvent {
  final String currentUserId;
  final String meetupId;

  const DeleteMeetupForUser({
    required this.currentUserId,
    required this.meetupId
  });

  @override
  List<Object?> get props => [currentUserId, meetupId];
}

class DissociateCardioDiaryEntryFromMeetup extends DetailedMeetupEvent {
  final String currentUserId;
  final String meetupId;
  final String cardioDiaryEntryId;

  const DissociateCardioDiaryEntryFromMeetup({
    required this.currentUserId,
    required this.meetupId,
    required this.cardioDiaryEntryId,
  });

  @override
  List<Object?> get props => [currentUserId, meetupId, cardioDiaryEntryId];
}

class DissociateStrengthDiaryEntryFromMeetup extends DetailedMeetupEvent {
  final String currentUserId;
  final String meetupId;
  final String strengthDiaryEntryId;

  const DissociateStrengthDiaryEntryFromMeetup({
    required this.currentUserId,
    required this.meetupId,
    required this.strengthDiaryEntryId,
  });

  @override
  List<Object?> get props => [currentUserId, meetupId, strengthDiaryEntryId];
}

class DissociateFoodDiaryEntryFromMeetup extends DetailedMeetupEvent {
  final String currentUserId;
  final String meetupId;
  final String foodDiaryEntryId;

  const DissociateFoodDiaryEntryFromMeetup({
    required this.currentUserId,
    required this.meetupId,
    required this.foodDiaryEntryId,
  });

  @override
  List<Object?> get props => [currentUserId, meetupId, foodDiaryEntryId];
}

// Delete existing associations and save afresh
class SaveAllDiaryEntriesAssociatedWithMeetup extends DetailedMeetupEvent {
  final String currentUserId;
  final String meetupId;
  final List<String> cardioDiaryEntryIds;
  final List<String> strengthDiaryEntryIds;
  final List<String> foodDiaryEntryIds;

  const SaveAllDiaryEntriesAssociatedWithMeetup({
    required this.currentUserId,
    required this.meetupId,
    required this.cardioDiaryEntryIds,
    required this.strengthDiaryEntryIds,
    required this.foodDiaryEntryIds,
  });

  @override
  List<Object?> get props => [
    currentUserId,
    meetupId,
    cardioDiaryEntryIds,
    strengthDiaryEntryIds,
    foodDiaryEntryIds,
  ];
}