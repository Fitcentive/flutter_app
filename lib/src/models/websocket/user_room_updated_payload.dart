import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_room_updated_payload.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserRoomUpdatedPayload extends Equatable {
  final String roomId;
  final String userId;

  const UserRoomUpdatedPayload(this.roomId, this.userId);

  @override
  List<Object> get props => [roomId, userId];

  factory UserRoomUpdatedPayload.fromJson(Map<String, dynamic> json) => _$UserRoomUpdatedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$UserRoomUpdatedPayloadToJson(this);
}