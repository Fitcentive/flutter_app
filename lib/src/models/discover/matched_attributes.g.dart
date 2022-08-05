// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matched_attributes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchedAttributes _$MatchedAttributesFromJson(Map<String, dynamic> json) =>
    MatchedAttributes(
      (json['activities'] as List<dynamic>?)?.map((e) => e as String).toList(),
      (json['fitnessGoals'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      (json['bodyTypes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      (json['genders'] as List<dynamic>?)?.map((e) => e as String).toList(),
      (json['preferredDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MatchedAttributesToJson(MatchedAttributes instance) =>
    <String, dynamic>{
      'activities': instance.activities,
      'fitnessGoals': instance.fitnessGoals,
      'bodyTypes': instance.bodyTypes,
      'genders': instance.genders,
      'preferredDays': instance.preferredDays,
    };
