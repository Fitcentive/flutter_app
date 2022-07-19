// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_socket_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebsocketEvent _$WebsocketEventFromJson(Map<String, dynamic> json) =>
    WebsocketEvent(
      json['event'] as String,
      json['payload'],
    );

Map<String, dynamic> _$WebsocketEventToJson(WebsocketEvent instance) =>
    <String, dynamic>{
      'event': instance.event,
      'payload': instance.payload,
    };
