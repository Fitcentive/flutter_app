import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatRoom extends Equatable {
  final String roomId;
  final List<String> userIds;

  const ChatRoom(this.roomId, this.userIds);

  @override
  List<Object> get props => [roomId, userIds];

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);
}