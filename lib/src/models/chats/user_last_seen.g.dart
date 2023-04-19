// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_last_seen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserLastSeen _$UserLastSeenFromJson(Map<String, dynamic> json) => UserLastSeen(
      json['room_id'] as String,
      json['user_id'] as String,
      DateTime.parse(json['last_seen'] as String),
      DateTime.parse(json['created_at'] as String),
      DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserLastSeenToJson(UserLastSeen instance) =>
    <String, dynamic>{
      'room_id': instance.roomId,
      'user_id': instance.userId,
      'last_seen': instance.lastSeen.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
