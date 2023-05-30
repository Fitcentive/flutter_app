import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarStateInitial extends CalendarState {

  const CalendarStateInitial();
}

class CalendarMeetupDataLoading extends CalendarState {

  const CalendarMeetupDataLoading();
}

class CalendarMeetupUserDataFetched extends CalendarState {
  final List<Meetup> meetups;
  final List<MeetupLocation?> meetupLocations;
  final Map<String, List<MeetupParticipant>> meetupParticipants;
  final Map<String, List<MeetupDecision>> meetupDecisions;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const CalendarMeetupUserDataFetched({
    required this.meetups,
    required this.meetupParticipants,
    required this.meetupLocations,
    required this.meetupDecisions,
    required this.userIdProfileMap,
  });

  @override
  List<Object?> get props => [
    meetups,
    meetupParticipants,
    meetupLocations,
    meetupDecisions,
    userIdProfileMap,
  ];
}