import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_admin.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatRoomAdmin extends Equatable {
  final String roomId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;


  const ChatRoomAdmin(this.roomId, this.userId, this.createdAt, this.updatedAt);

  @override
  List<Object> get props => [roomId, userId, createdAt, updatedAt];

  factory ChatRoomAdmin.fromJson(Map<String, dynamic> json) => _$ChatRoomAdminFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomAdminToJson(this);
}