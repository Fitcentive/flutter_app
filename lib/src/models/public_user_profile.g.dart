// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicUserProfile _$PublicUserProfileFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['userId'],
  );
  return PublicUserProfile(
    json['userId'] as String,
    json['username'] as String?,
    json['firstName'] as String?,
    json['lastName'] as String?,
    json['photoUrl'] as String?,
    json['locationRadius'] as int?,
    json['locationCenter'] == null
        ? null
        : Coordinates.fromJson(json['locationCenter'] as Map<String, dynamic>),
    json['gender'] as String?,
  );
}

Map<String, dynamic> _$PublicUserProfileToJson(PublicUserProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'photoUrl': instance.photoUrl,
      'locationRadius': instance.locationRadius,
      'locationCenter': instance.locationCenter,
      'gender': instance.gender,
    };
