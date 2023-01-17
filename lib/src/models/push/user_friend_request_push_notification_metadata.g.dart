// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_friend_request_push_notification_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFriendRequestPushNotificationMetadata
    _$UserFriendRequestPushNotificationMetadataFromJson(
            Map<String, dynamic> json) =>
        UserFriendRequestPushNotificationMetadata(
          json['type'] as String,
          json['requestingUserId'] as String,
          json['targetUserId'] as String,
          json['requestingUserPhotoUrl'] as String,
        );

Map<String, dynamic> _$UserFriendRequestPushNotificationMetadataToJson(
        UserFriendRequestPushNotificationMetadata instance) =>
    <String, dynamic>{
      'type': instance.type,
      'requestingUserId': instance.requestingUserId,
      'targetUserId': instance.targetUserId,
      'requestingUserPhotoUrl': instance.requestingUserPhotoUrl,
    };
