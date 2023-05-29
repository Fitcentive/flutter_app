// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_all_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAllPreferences _$UserAllPreferencesFromJson(Map<String, dynamic> json) =>
    UserAllPreferences(
      json['userDiscoveryPreferences'] == null
          ? null
          : UserDiscoveryPreferences.fromJson(
              json['userDiscoveryPreferences'] as Map<String, dynamic>),
      json['userGymPreferences'] == null
          ? null
          : UserGymPreferences.fromJson(
              json['userGymPreferences'] as Map<String, dynamic>),
      json['userFitnessPreferences'] == null
          ? null
          : UserFitnessPreferences.fromJson(
              json['userFitnessPreferences'] as Map<String, dynamic>),
      json['userPersonalPreferences'] == null
          ? null
          : UserPersonalPreferences.fromJson(
              json['userPersonalPreferences'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserAllPreferencesToJson(UserAllPreferences instance) =>
    <String, dynamic>{
      'userDiscoveryPreferences': instance.userDiscoveryPreferences,
      'userGymPreferences': instance.userGymPreferences,
      'userFitnessPreferences': instance.userFitnessPreferences,
      'userPersonalPreferences': instance.userPersonalPreferences,
    };
