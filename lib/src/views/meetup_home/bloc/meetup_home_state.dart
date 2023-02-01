import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class MeetupHomeState extends Equatable {
  const MeetupHomeState();

  @override
  List<Object?> get props => [];
}

class MeetupHomeStateInitial extends MeetupHomeState {

  const MeetupHomeStateInitial();
}

class MeetupUserDataFetched extends MeetupHomeState {
  final List<Meetup> meetups;
  final List<MeetupLocation?> meetupLocations;
  final Map<String, List<MeetupParticipant>> meetupParticipants;
  final Map<String, List<MeetupDecision>> meetupDecisions;
  final Map<String, PublicUserProfile> userIdProfileMap;
  final bool doesNextPageExist;

  const MeetupUserDataFetched({
    required this.meetups,
    required this.meetupParticipants,
    required this.meetupLocations,
    required this.meetupDecisions,
    required this.userIdProfileMap,
    required this.doesNextPageExist,
  });

  @override
  List<Object?> get props => [
    meetups,
    doesNextPageExist,
    meetupParticipants,
    meetupLocations,
    meetupDecisions,
    userIdProfileMap,
  ];
}