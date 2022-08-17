// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_push_notification_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessagePushNotificationMetadata
    _$ChatMessagePushNotificationMetadataFromJson(Map<String, dynamic> json) =>
        ChatMessagePushNotificationMetadata(
          json['targetUserId'] as String,
          json['sendingUserId'] as String,
          json['sendingUserPhotoUrl'] as String,
          json['type'] as String,
          json['roomId'] as String,
        );

Map<String, dynamic> _$ChatMessagePushNotificationMetadataToJson(
        ChatMessagePushNotificationMetadata instance) =>
    <String, dynamic>{
      'targetUserId': instance.targetUserId,
      'sendingUserId': instance.sendingUserId,
      'sendingUserPhotoUrl': instance.sendingUserPhotoUrl,
      'type': instance.type,
      'roomId': instance.roomId,
    };
