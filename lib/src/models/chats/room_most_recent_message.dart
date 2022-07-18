import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room_most_recent_message.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RoomMostRecentMessage extends Equatable {
  final String roomId;
  final String mostRecentMessage;

  const RoomMostRecentMessage(this.roomId, this.mostRecentMessage);

  @override
  List<Object> get props => [roomId, mostRecentMessage];

  factory RoomMostRecentMessage.fromJson(Map<String, dynamic> json) => _$RoomMostRecentMessageFromJson(json);

  Map<String, dynamic> toJson() => _$RoomMostRecentMessageToJson(this);
}