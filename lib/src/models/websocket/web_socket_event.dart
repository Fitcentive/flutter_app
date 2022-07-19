import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'web_socket_event.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WebsocketEvent extends Equatable {
  final String event;
  final dynamic payload;

  const WebsocketEvent(this.event, this.payload);

  @override
  List<Object> get props => [event, payload];

  factory WebsocketEvent.fromJson(Map<String, dynamic> json) => _$WebsocketEventFromJson(json);

  Map<String, dynamic> toJson() => _$WebsocketEventToJson(this);

}
