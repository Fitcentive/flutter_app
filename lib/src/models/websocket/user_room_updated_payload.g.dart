// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_room_updated_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRoomUpdatedPayload _$UserRoomUpdatedPayloadFromJson(
        Map<String, dynamic> json) =>
    UserRoomUpdatedPayload(
      json['room_id'] as String,
      json['user_id'] as String,
    );

Map<String, dynamic> _$UserRoomUpdatedPayloadToJson(
        UserRoomUpdatedPayload instance) =>
    <String, dynamic>{
      'room_id': instance.roomId,
      'user_id': instance.userId,
    };
