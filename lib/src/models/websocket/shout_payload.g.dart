// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shout_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoutPayload _$ShoutPayloadFromJson(Map<String, dynamic> json) => ShoutPayload(
      json['user_id'] as String,
      json['body'] as String,
    );

Map<String, dynamic> _$ShoutPayloadToJson(ShoutPayload instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'body': instance.body,
    };
