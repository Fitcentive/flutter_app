import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class SelectFromMeetupsState extends Equatable {
  const SelectFromMeetupsState();

  @override
  List<Object?> get props => [];
}

class SelectFromMeetupsStateInitial extends SelectFromMeetupsState {

  const SelectFromMeetupsStateInitial();
}

class MeetupDataLoading extends SelectFromMeetupsState {

  const MeetupDataLoading();
}

class MeetupUserDataFetched extends SelectFromMeetupsState {
  final List<Meetup> meetups;
  final Map<String, List<MeetupParticipant>> meetupParticipants;
  final Map<String, List<MeetupDecision>> meetupDecisions;
  final Map<String, PublicUserProfile> userIdProfileMap;
  final bool doesNextPageExist;

  const MeetupUserDataFetched({
    required this.meetups,
    required this.meetupParticipants,
    required this.meetupDecisions,
    required this.userIdProfileMap,
    required this.doesNextPageExist,
  });

  @override
  List<Object?> get props => [
    meetups,
    doesNextPageExist,
    meetupParticipants,
    meetupDecisions,
    userIdProfileMap,
  ];
}