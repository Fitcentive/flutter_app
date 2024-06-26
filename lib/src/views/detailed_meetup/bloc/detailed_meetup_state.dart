import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
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

  final Map<String, AllDiaryEntries> participantDiaryEntriesMap;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> rawFoodEntries;

  const DetailedMeetupDataFetched({
    required this.meetupId,
    required this.userAvailabilities,
    required this.meetupLocation,
    required this.meetup,
    required this.participants,
    required this.decisions,
    required this.userProfiles,
    required this.participantDiaryEntriesMap,
    required this.rawFoodEntries,
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
    participantDiaryEntriesMap,
    rawFoodEntries,
  ];
}

class MeetupDeletedAndReadyToPop extends DetailedMeetupState {

  const MeetupDeletedAndReadyToPop();

  @override
  List<Object?> get props => [];
}

class ErrorState extends DetailedMeetupState {

  const ErrorState();

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