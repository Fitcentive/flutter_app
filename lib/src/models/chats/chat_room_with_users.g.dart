// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_with_users.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomWithUsers _$ChatRoomWithUsersFromJson(Map<String, dynamic> json) =>
    ChatRoomWithUsers(
      json['room_id'] as String,
      (json['user_ids'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ChatRoomWithUsersToJson(ChatRoomWithUsers instance) =>
    <String, dynamic>{
      'room_id': instance.roomId,
      'user_ids': instance.userIds,
    };
