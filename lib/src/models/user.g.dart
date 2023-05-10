// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'email'],
  );
  return User(
    json['id'] as String,
    json['email'] as String,
    json['username'] as String?,
    json['accountStatus'] as String,
    json['authProvider'] as String,
    json['enabled'] as bool,
    json['isPremiumEnabled'] as bool,
    DateTime.parse(json['createdAt'] as String),
    DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'accountStatus': instance.accountStatus,
      'authProvider': instance.authProvider,
      'enabled': instance.enabled,
      'isPremiumEnabled': instance.isPremiumEnabled,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
