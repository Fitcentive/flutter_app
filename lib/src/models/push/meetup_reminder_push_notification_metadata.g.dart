// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_reminder_push_notification_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupReminderPushNotificationMetadata
    _$MeetupReminderPushNotificationMetadataFromJson(
            Map<String, dynamic> json) =>
        MeetupReminderPushNotificationMetadata(
          json['type'] as String,
          json['meetupId'] as String,
          json['targetUser'] as String,
        );

Map<String, dynamic> _$MeetupReminderPushNotificationMetadataToJson(
        MeetupReminderPushNotificationMetadata instance) =>
    <String, dynamic>{
      'type': instance.type,
      'meetupId': instance.meetupId,
      'targetUser': instance.targetUser,
    };
