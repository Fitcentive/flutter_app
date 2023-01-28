// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupParticipant _$MeetupParticipantFromJson(Map<String, dynamic> json) =>
    MeetupParticipant(
      json['meetupId'] as String,
      json['userId'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupParticipantToJson(MeetupParticipant instance) =>
    <String, dynamic>{
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
