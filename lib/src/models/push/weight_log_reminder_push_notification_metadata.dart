import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weight_log_reminder_push_notification_metadata.g.dart';

@JsonSerializable()
class WeightLogReminderPushNotificationMetadata extends Equatable {
  final String type;
  final String targetUser;


  const WeightLogReminderPushNotificationMetadata(
      this.type,
      this.targetUser,
      );

  factory WeightLogReminderPushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$WeightLogReminderPushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$WeightLogReminderPushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [type, targetUser];
}