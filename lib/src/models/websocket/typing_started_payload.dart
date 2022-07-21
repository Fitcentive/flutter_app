import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'typing_started_payload.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TypingStartedPayload extends Equatable {
  final String userId;

  const TypingStartedPayload(this.userId);

  @override
  List<Object> get props => [userId];

  factory TypingStartedPayload.fromJson(Map<String, dynamic> json) => _$TypingStartedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$TypingStartedPayloadToJson(this);
}