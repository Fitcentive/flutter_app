// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detailed_chat_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetailedChatRoom _$DetailedChatRoomFromJson(Map<String, dynamic> json) =>
    DetailedChatRoom(
      json['room_id'] as String,
      json['room_name'] as String,
      json['room_type'] as String,
      json['enabled'] as bool,
      DateTime.parse(json['created_at'] as String),
      DateTime.parse(json['updated_at'] as String),
      json['most_recent_message'] as String?,
      json['most_recent_message_timestamp'] == null
          ? null
          : DateTime.parse(json['most_recent_message_timestamp'] as String),
      (json['user_ids'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DetailedChatRoomToJson(DetailedChatRoom instance) =>
    <String, dynamic>{
      'room_id': instance.roomId,
      'room_name': instance.roomName,
      'room_type': instance.roomType,
      'enabled': instance.enabled,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'most_recent_message': instance.mostRecentMessage,
      'most_recent_message_timestamp':
          instance.mostRecentMessageTimestamp?.toIso8601String(),
      'user_ids': instance.userIds,
    };
