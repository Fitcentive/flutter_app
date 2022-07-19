import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom(this.id, this.name, this.type, this.createdAt, this.updatedAt);

  @override
  List<Object> get props => [id, name, type, createdAt, updatedAt];

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);
}