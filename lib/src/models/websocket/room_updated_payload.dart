import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room_updated_payload.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RoomUpdatedPayload extends Equatable {
  final String roomId;

  const RoomUpdatedPayload(this.roomId);

  @override
  List<Object> get props => [roomId];

  factory RoomUpdatedPayload.fromJson(Map<String, dynamic> json) => _$RoomUpdatedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RoomUpdatedPayloadToJson(this);
}