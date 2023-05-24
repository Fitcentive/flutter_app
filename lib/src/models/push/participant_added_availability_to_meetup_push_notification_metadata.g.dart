// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_added_availability_to_meetup_push_notification_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantAddedAvailabilityToMeetupPushNotificationMetadata
    _$ParticipantAddedAvailabilityToMeetupPushNotificationMetadataFromJson(
            Map<String, dynamic> json) =>
        ParticipantAddedAvailabilityToMeetupPushNotificationMetadata(
          json['type'] as String,
          json['meetupId'] as String,
          json['participantId'] as String,
          json['participantPhotoUrl'] as String,
          json['participantName'] as String,
          json['meetupOwnerId'] as String,
          json['targetUserId'] as String,
        );

Map<String, dynamic>
    _$ParticipantAddedAvailabilityToMeetupPushNotificationMetadataToJson(
            ParticipantAddedAvailabilityToMeetupPushNotificationMetadata
                instance) =>
        <String, dynamic>{
          'type': instance.type,
          'meetupId': instance.meetupId,
          'participantId': instance.participantId,
          'participantPhotoUrl': instance.participantPhotoUrl,
          'participantName': instance.participantName,
          'meetupOwnerId': instance.meetupOwnerId,
          'targetUserId': instance.targetUserId,
        };
