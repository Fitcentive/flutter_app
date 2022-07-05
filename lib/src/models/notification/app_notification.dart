import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

@JsonSerializable()
class AppNotification {
  String id;
  String targetUser;
  String notificationType;
  bool isInteractive;
  bool hasBeenInteractedWith;
  Map<dynamic, dynamic> data;
  DateTime createdAt;
  DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.targetUser,
    required this.notificationType,
    required this.isInteractive,
    required this.hasBeenInteractedWith,
    required this.data,
    required this.createdAt,
    required this.updatedAt
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}
