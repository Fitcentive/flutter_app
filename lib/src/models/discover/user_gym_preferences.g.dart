// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_gym_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserGymPreferences _$UserGymPreferencesFromJson(Map<String, dynamic> json) =>
    UserGymPreferences(
      json['userId'] as String,
      json['gymLocationId'] as String?,
      json['fsqId'] as String?,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserGymPreferencesToJson(UserGymPreferences instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'gymLocationId': instance.gymLocationId,
      'fsqId': instance.fsqId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
