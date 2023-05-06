import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_reminder_push_notification_metadata.g.dart';

@JsonSerializable()
class MeetupReminderPushNotificationMetadata extends Equatable {
  final String type;
  final String meetupId;
  final String targetUser;


  const MeetupReminderPushNotificationMetadata(
      this.type,
      this.meetupId,
      this.targetUser,
      );

  factory MeetupReminderPushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$MeetupReminderPushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupReminderPushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [type, meetupId, targetUser];
}