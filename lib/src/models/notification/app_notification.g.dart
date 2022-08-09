// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      targetUser: json['targetUser'] as String,
      notificationType: json['notificationType'] as String,
      isInteractive: json['isInteractive'] as bool,
      hasBeenInteractedWith: json['hasBeenInteractedWith'] as bool,
      hasBeenViewed: json['hasBeenViewed'] as bool,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'targetUser': instance.targetUser,
      'notificationType': instance.notificationType,
      'isInteractive': instance.isInteractive,
      'hasBeenInteractedWith': instance.hasBeenInteractedWith,
      'hasBeenViewed': instance.hasBeenViewed,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
