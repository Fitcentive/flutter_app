// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_added_to_meetup_push_notification_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantAddedToMeetupPushNotificationMetadata
    _$ParticipantAddedToMeetupPushNotificationMetadataFromJson(
            Map<String, dynamic> json) =>
        ParticipantAddedToMeetupPushNotificationMetadata(
          json['type'] as String,
          json['meetupId'] as String,
          json['meetupOwnerId'] as String,
          json['participantId'] as String,
          json['meetupOwnerPhotoUrl'] as String,
        );

Map<String, dynamic> _$ParticipantAddedToMeetupPushNotificationMetadataToJson(
        ParticipantAddedToMeetupPushNotificationMetadata instance) =>
    <String, dynamic>{
      'type': instance.type,
      'meetupOwnerId': instance.meetupOwnerId,
      'meetupId': instance.meetupId,
      'participantId': instance.participantId,
      'meetupOwnerPhotoUrl': instance.meetupOwnerPhotoUrl,
    };
