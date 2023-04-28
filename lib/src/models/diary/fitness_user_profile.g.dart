// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FitnessUserProfile _$FitnessUserProfileFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['userId'],
  );
  return FitnessUserProfile(
    json['userId'] as String,
    (json['heightInCm'] as num).toDouble(),
    (json['weightInLbs'] as num).toDouble(),
    DateTime.parse(json['createdAt'] as String),
    DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$FitnessUserProfileToJson(FitnessUserProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'heightInCm': instance.heightInCm,
      'weightInLbs': instance.weightInLbs,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
