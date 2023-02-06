// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupComment _$MeetupCommentFromJson(Map<String, dynamic> json) =>
    MeetupComment(
      json['id'] as String,
      json['meetupId'] as String,
      json['userId'] as String,
      json['comment'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupCommentToJson(MeetupComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
