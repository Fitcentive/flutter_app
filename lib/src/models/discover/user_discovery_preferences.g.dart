// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_discovery_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDiscoveryPreferences _$UserDiscoveryPreferencesFromJson(
        Map<String, dynamic> json) =>
    UserDiscoveryPreferences(
      json['userId'] as String,
      json['preferredTransportMode'] as String,
      Coordinates.fromJson(json['locationCenter'] as Map<String, dynamic>),
      json['locationRadius'] as int,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserDiscoveryPreferencesToJson(
        UserDiscoveryPreferences instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'preferredTransportMode': instance.preferredTransportMode,
      'locationCenter': instance.locationCenter,
      'locationRadius': instance.locationRadius,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
