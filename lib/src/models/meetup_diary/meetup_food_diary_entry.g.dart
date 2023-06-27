// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_food_diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupFoodDiaryEntry _$MeetupFoodDiaryEntryFromJson(
        Map<String, dynamic> json) =>
    MeetupFoodDiaryEntry(
      json['meetupId'] as String,
      json['userId'] as String,
      json['foodEntryId'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupFoodDiaryEntryToJson(
        MeetupFoodDiaryEntry instance) =>
    <String, dynamic>{
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'foodEntryId': instance.foodEntryId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
