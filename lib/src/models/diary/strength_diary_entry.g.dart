// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthDiaryEntry _$StrengthDiaryEntryFromJson(Map<String, dynamic> json) =>
    StrengthDiaryEntry(
      json['id'] as String,
      json['userId'] as String,
      json['workoutId'] as String,
      json['name'] as String,
      DateTime.parse(json['exerciseDate'] as String),
      json['sets'] as int,
      json['reps'] as int,
      (json['weightsInLbs'] as List<dynamic>).map((e) => e as int).toList(),
      (json['caloriesBurned'] as num).toDouble(),
      json['meetupId'] as String?,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StrengthDiaryEntryToJson(StrengthDiaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'workoutId': instance.workoutId,
      'name': instance.name,
      'exerciseDate': instance.exerciseDate.toIso8601String(),
      'sets': instance.sets,
      'reps': instance.reps,
      'weightsInLbs': instance.weightsInLbs,
      'caloriesBurned': instance.caloriesBurned,
      'meetupId': instance.meetupId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
