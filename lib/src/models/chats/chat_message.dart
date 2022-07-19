import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String roomId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMessage(this.id, this.senderId, this.roomId, this.text, this.imageUrl, this.createdAt, this.updatedAt);

  @override
  List<Object?> get props => [
    id,
    senderId,
    roomId,
    text,
    imageUrl,
    createdAt,
    updatedAt,
  ];

  ChatMessage copyWithLocalTime() =>
      ChatMessage(id, senderId, roomId, text, imageUrl, createdAt.toLocal(), updatedAt.toLocal());

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}