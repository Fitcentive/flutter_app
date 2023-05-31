import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'detailed_chat_room.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DetailedChatRoom extends Equatable {
  final String roomId;
  final String roomName;
  final String roomType;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? mostRecentMessage;
  final DateTime? mostRecentMessageTimestamp;

  final List<String> userIds;

  const DetailedChatRoom(
      this.roomId,
      this.roomName,
      this.roomType,
      this.enabled,
      this.createdAt,
      this.updatedAt,
      this.mostRecentMessage,
      this.mostRecentMessageTimestamp,
      this.userIds
  );

  @override
  List<Object?> get props => [
    roomId,
    roomName,
    roomType,
    enabled,
    createdAt,
    updatedAt,
    mostRecentMessage,
    mostRecentMessageTimestamp,
    userIds,
  ];

  factory DetailedChatRoom.fromJson(Map<String, dynamic> json) => _$DetailedChatRoomFromJson(json);

  Map<String, dynamic> toJson() => _$DetailedChatRoomToJson(this);

}