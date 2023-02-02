import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';

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

  const DetailedMeetupDataFetched({
    required this.meetupId,
    required this.userAvailabilities,
    required this.meetupLocation,
  });

  @override
  List<Object?> get props => [userAvailabilities, meetupId, meetupLocation];
}