// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['userId'],
  );
  return UserProfile(
    json['userId'] as String,
    json['firstName'] as String?,
    json['lastName'] as String?,
    json['photoUrl'] as String?,
    json['dateOfBirth'] as String?,
    json['locationRadius'] as int?,
    json['locationCenter'] == null
        ? null
        : Coordinates.fromJson(json['locationCenter'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'photoUrl': instance.photoUrl,
      'dateOfBirth': instance.dateOfBirth,
      'locationRadius': instance.locationRadius,
      'locationCenter': instance.locationCenter,
    };
