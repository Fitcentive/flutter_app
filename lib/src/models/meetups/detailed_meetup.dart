import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:json_annotation/json_annotation.dart';

part 'detailed_meetup.g.dart';

@JsonSerializable()
class DetailedMeetup extends Equatable {
  final Meetup meetup;
  final MeetupLocation? location;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;

  const DetailedMeetup(
      this.meetup,
      this.location,
      this.participants,
      this.decisions
  );

  factory DetailedMeetup.fromJson(Map<String, dynamic> json) => _$DetailedMeetupFromJson(json);

  Map<String, dynamic> toJson() => _$DetailedMeetupToJson(this);

  @override
  List<Object?> get props => [
    meetup,
    location,
    participants,
    decisions
  ];
}