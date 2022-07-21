import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_push_notification_metadata.g.dart';

@JsonSerializable()
class ChatMessagePushNotificationMetadata extends Equatable {
  final String targetUserId;
  final String sendingUserId;
  final String type;
  final String roomId;

  const ChatMessagePushNotificationMetadata(this.targetUserId, this.sendingUserId, this.type, this.roomId);

  factory ChatMessagePushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$ChatMessagePushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessagePushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [targetUserId, sendingUserId, type, roomId];
}