// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_personal_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPersonalPreferences _$UserPersonalPreferencesFromJson(
        Map<String, dynamic> json) =>
    UserPersonalPreferences(
      json['userId'] as String,
      (json['gendersInterestedIn'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      (json['preferredDays'] as List<dynamic>).map((e) => e as String).toList(),
      json['minimumAge'] as int,
      json['maximumAge'] as int,
      (json['hoursPerWeek'] as num).toDouble(),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserPersonalPreferencesToJson(
        UserPersonalPreferences instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'gendersInterestedIn': instance.gendersInterestedIn,
      'preferredDays': instance.preferredDays,
      'minimumAge': instance.minimumAge,
      'maximumAge': instance.maximumAge,
      'hoursPerWeek': instance.hoursPerWeek,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
