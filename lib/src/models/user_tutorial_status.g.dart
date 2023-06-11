// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_tutorial_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserTutorialStatus _$UserTutorialStatusFromJson(Map<String, dynamic> json) =>
    UserTutorialStatus(
      json['userId'] as String,
      json['isTutorialComplete'] as bool,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserTutorialStatusToJson(UserTutorialStatus instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'isTutorialComplete': instance.isTutorialComplete,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
