// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_decision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupDecision _$MeetupDecisionFromJson(Map<String, dynamic> json) =>
    MeetupDecision(
      json['meetupId'] as String,
      json['userId'] as String,
      json['hasAccepted'] as bool,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupDecisionToJson(MeetupDecision instance) =>
    <String, dynamic>{
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'hasAccepted': instance.hasAccepted,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
