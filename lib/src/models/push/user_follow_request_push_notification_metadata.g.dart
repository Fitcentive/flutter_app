// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_follow_request_push_notification_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFollowRequestPushNotificationMetadata
    _$UserFollowRequestPushNotificationMetadataFromJson(
            Map<String, dynamic> json) =>
        UserFollowRequestPushNotificationMetadata(
          json['type'] as String,
          json['requestingUserId'] as String,
          json['targetUserId'] as String,
          json['requestingUserPhotoUrl'] as String,
        );

Map<String, dynamic> _$UserFollowRequestPushNotificationMetadataToJson(
        UserFollowRequestPushNotificationMetadata instance) =>
    <String, dynamic>{
      'type': instance.type,
      'requestingUserId': instance.requestingUserId,
      'targetUserId': instance.targetUserId,
      'requestingUserPhotoUrl': instance.requestingUserPhotoUrl,
    };
