import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_with_users.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatRoomWithUsers extends Equatable {
  final String roomId;
  final List<String> userIds;

  const ChatRoomWithUsers(this.roomId, this.userIds);

  @override
  List<Object> get props => [roomId, userIds];

  factory ChatRoomWithUsers.fromJson(Map<String, dynamic> json) => _$ChatRoomWithUsersFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomWithUsersToJson(this);
}