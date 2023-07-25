// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_steps_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStepsData _$UserStepsDataFromJson(Map<String, dynamic> json) =>
    UserStepsData(
      json['id'] as String,
      json['userId'] as String,
      json['steps'] as int,
      (json['caloriesBurned'] as num).toDouble(),
      json['entryDate'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserStepsDataToJson(UserStepsData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'steps': instance.steps,
      'caloriesBurned': instance.caloriesBurned,
      'entryDate': instance.entryDate,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
