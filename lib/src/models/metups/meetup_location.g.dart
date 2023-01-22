// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetup_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetupLocation _$MeetupLocationFromJson(Map<String, dynamic> json) =>
    MeetupLocation(
      json['id'] as String,
      json['fsqId'] as String,
      json['locationName'] as String?,
      json['website'] as String?,
      json['phone'] as String?,
      Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MeetupLocationToJson(MeetupLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fsqId': instance.fsqId,
      'locationName': instance.locationName,
      'website': instance.website,
      'phone': instance.phone,
      'coordinates': instance.coordinates,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
