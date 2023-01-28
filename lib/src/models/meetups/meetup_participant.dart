import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_participant.g.dart';

@JsonSerializable()
class MeetupParticipant extends Equatable {
  final String meetupId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetupParticipant(
      this.meetupId,
      this.userId,
      this.createdAt,
      this.updatedAt
  );

  factory MeetupParticipant.fromJson(Map<String, dynamic> json) => _$MeetupParticipantFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupParticipantToJson(this);

  @override
  List<Object?> get props => [
    meetupId,
    userId,
    createdAt,
    updatedAt,
  ];
}