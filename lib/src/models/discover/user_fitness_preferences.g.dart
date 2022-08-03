// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_fitness_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFitnessPreferences _$UserFitnessPreferencesFromJson(
        Map<String, dynamic> json) =>
    UserFitnessPreferences(
      json['userId'] as String,
      (json['activitiesInterestedIn'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      (json['fitnessGoals'] as List<dynamic>).map((e) => e as String).toList(),
      (json['desiredBodyTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserFitnessPreferencesToJson(
        UserFitnessPreferences instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'activitiesInterestedIn': instance.activitiesInterestedIn,
      'fitnessGoals': instance.fitnessGoals,
      'desiredBodyTypes': instance.desiredBodyTypes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
