import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'typing_stopped_payload.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TypingStoppedPayload extends Equatable {
  final String userId;

  const TypingStoppedPayload(this.userId);

  @override
  List<Object> get props => [userId];

  factory TypingStoppedPayload.fromJson(Map<String, dynamic> json) => _$TypingStoppedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$TypingStoppedPayloadToJson(this);
}