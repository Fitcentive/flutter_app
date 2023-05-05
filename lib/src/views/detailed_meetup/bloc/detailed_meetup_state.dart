import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DetailedMeetupState extends Equatable {
  const DetailedMeetupState();

  @override
  List<Object?> get props => [];
}

class DetailedMeetupStateInitial extends DetailedMeetupState {

  const DetailedMeetupStateInitial();

  @override
  List<Object?> get props => [];
}

class DetailedMeetupStateLoading extends DetailedMeetupState {

  const DetailedMeetupStateLoading();

  @override
  List<Object?> get props => [];
}

class DetailedMeetupDataFetched extends DetailedMeetupState {
  final String meetupId;
  final Location? meetupLocation;
  final Map<String, List<MeetupAvailability>> userAvailabilities;

  final Meetup meetup;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;
  final List<PublicUserProfile> userProfiles;

  const DetailedMeetupDataFetched({
    required this.meetupId,
    required this.userAvailabilities,
    required this.meetupLocation,
    required this.meetup,
    required this.participants,
    required this.decisions,
    required this.userProfiles,
  });

  @override
  List<Object?> get props => [
    userAvailabilities,
    meetupId,
    meetupLocation,
    meetup,
    participants,
    decisions,
    userProfiles,
  ];
}

class MeetupUpdatedAndReadyToPop extends DetailedMeetupState {

  const MeetupUpdatedAndReadyToPop();

  @override
  List<Object?> get props => [];
}

class MeetupDeletedAndReadyToPop extends DetailedMeetupState {

  const MeetupDeletedAndReadyToPop();

  @override
  List<Object?> get props => [];
}

class MeetupChatRoomCreated extends DetailedMeetupState {
  final String chatRoomId;
  // RandomId used with Equatable to force fetch chat room id each time
  final String randomId;

  const MeetupChatRoomCreated({required this.chatRoomId, required this.randomId});

  @override
  List<Object?> get props => [chatRoomId, randomId];
}