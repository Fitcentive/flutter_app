// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_cardio_diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupCardioDiaryEntry _$MeetupCardioDiaryEntryFromJson(
        Map<String, dynamic> json) =>
    MeetupCardioDiaryEntry(
      json['meetupId'] as String,
      json['userId'] as String,
      json['cardioEntryId'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupCardioDiaryEntryToJson(
        MeetupCardioDiaryEntry instance) =>
    <String, dynamic>{
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'cardioEntryId': instance.cardioEntryId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
