// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_most_recent_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomMostRecentMessage _$RoomMostRecentMessageFromJson(
        Map<String, dynamic> json) =>
    RoomMostRecentMessage(
      json['room_id'] as String,
      json['most_recent_message'] as String,
      DateTime.parse(json['most_recent_message_time'] as String),
    );

Map<String, dynamic> _$RoomMostRecentMessageToJson(
        RoomMostRecentMessage instance) =>
    <String, dynamic>{
      'room_id': instance.roomId,
      'most_recent_message': instance.mostRecentMessage,
      'most_recent_message_time':
          instance.mostRecentMessageTime.toIso8601String(),
    };
