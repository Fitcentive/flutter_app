import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shout_payload.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShoutPayload extends Equatable {
  final String userId;
  final String body;

  const ShoutPayload(this.userId, this.body);

  @override
  List<Object> get props => [userId, body];

  factory ShoutPayload.fromJson(Map<String, dynamic> json) => _$ShoutPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ShoutPayloadToJson(this);
}