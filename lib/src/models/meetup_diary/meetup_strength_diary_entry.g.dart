// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_strength_diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupStrengthDiaryEntry _$MeetupStrengthDiaryEntryFromJson(
        Map<String, dynamic> json) =>
    MeetupStrengthDiaryEntry(
      json['meetupId'] as String,
      json['userId'] as String,
      json['strengthEntryId'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupStrengthDiaryEntryToJson(
        MeetupStrengthDiaryEntry instance) =>
    <String, dynamic>{
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'strengthEntryId': instance.strengthEntryId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
