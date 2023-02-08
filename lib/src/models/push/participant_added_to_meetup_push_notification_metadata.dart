import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'participant_added_to_meetup_push_notification_metadata.g.dart';

@JsonSerializable()
class ParticipantAddedToMeetupPushNotificationMetadata extends Equatable {
  final String type;
  final String meetupId;
  final String meetupOwnerId;
  final String participantId;
  final String meetupOwnerPhotoUrl;


  const ParticipantAddedToMeetupPushNotificationMetadata(
      this.type,
      this.meetupId,
      this.meetupOwnerId,
      this.participantId,
      this.meetupOwnerPhotoUrl
  );

  factory ParticipantAddedToMeetupPushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$ParticipantAddedToMeetupPushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantAddedToMeetupPushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [type, meetupId, meetupOwnerId, participantId, meetupOwnerPhotoUrl];
}