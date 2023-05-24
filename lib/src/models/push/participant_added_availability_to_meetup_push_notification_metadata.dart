import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'participant_added_availability_to_meetup_push_notification_metadata.g.dart';

@JsonSerializable()
class ParticipantAddedAvailabilityToMeetupPushNotificationMetadata extends Equatable {
  final String type;
  final String meetupId;
  final String participantId;
  final String participantPhotoUrl;
  final String participantName;
  final String meetupOwnerId;
  final String targetUserId;


  const ParticipantAddedAvailabilityToMeetupPushNotificationMetadata(
      this.type,
      this.meetupId,
      this.participantId,
      this.participantPhotoUrl,
      this.participantName,
      this.meetupOwnerId,
      this.targetUserId
      );

  factory ParticipantAddedAvailabilityToMeetupPushNotificationMetadata.fromJson(Map<String, dynamic> json) =>
      _$ParticipantAddedAvailabilityToMeetupPushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantAddedAvailabilityToMeetupPushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [
    type,
    meetupId,
    participantId,
    participantPhotoUrl,
    participantName,
    meetupOwnerId,
    targetUserId,
  ];
}