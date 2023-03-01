// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardioDiaryEntry _$CardioDiaryEntryFromJson(Map<String, dynamic> json) =>
    CardioDiaryEntry(
      json['id'] as String,
      json['userId'] as String,
      json['workoutId'] as String,
      json['name'] as String,
      DateTime.parse(json['cardioDate'] as String),
      json['durationInMinutes'] as int,
      (json['caloriesBurned'] as num).toDouble(),
      json['meetupId'] as String?,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CardioDiaryEntryToJson(CardioDiaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'workoutId': instance.workoutId,
      'name': instance.name,
      'cardioDate': instance.cardioDate.toIso8601String(),
      'durationInMinutes': instance.durationInMinutes,
      'caloriesBurned': instance.caloriesBurned,
      'meetupId': instance.meetupId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
