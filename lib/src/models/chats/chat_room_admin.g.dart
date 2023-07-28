// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_admin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomAdmin _$ChatRoomAdminFromJson(Map<String, dynamic> json) =>
    ChatRoomAdmin(
      json['room_id'] as String,
      json['user_id'] as String,
      DateTime.parse(json['created_at'] as String),
      DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ChatRoomAdminToJson(ChatRoomAdmin instance) =>
    <String, dynamic>{
      'room_id': instance.roomId,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
