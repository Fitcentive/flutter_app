// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meetup _$MeetupFromJson(Map<String, dynamic> json) => Meetup(
      json['id'] as String,
      json['ownerId'] as String,
      json['meetupType'] as String,
      json['meetupStatus'] as String,
      json['name'] as String?,
      json['time'] == null ? null : DateTime.parse(json['time'] as String),
      json['durationInMinutes'] as int?,
      json['locationId'] as String?,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupToJson(Meetup instance) => <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'meetupType': instance.meetupType,
      'meetupStatus': instance.meetupStatus,
      'name': instance.name,
      'time': instance.time?.toIso8601String(),
      'durationInMinutes': instance.durationInMinutes,
      'locationId': instance.locationId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
