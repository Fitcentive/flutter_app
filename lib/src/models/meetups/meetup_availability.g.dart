// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_availability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupAvailability _$MeetupAvailabilityFromJson(Map<String, dynamic> json) =>
    MeetupAvailability(
      json['id'] as String,
      json['meetupId'] as String,
      json['userId'] as String,
      DateTime.parse(json['availabilityStart'] as String),
      DateTime.parse(json['availabilityEnd'] as String),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupAvailabilityToJson(MeetupAvailability instance) =>
    <String, dynamic>{
      'id': instance.id,
      'meetupId': instance.meetupId,
      'userId': instance.userId,
      'availabilityStart': instance.availabilityStart.toIso8601String(),
      'availabilityEnd': instance.availabilityEnd.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
