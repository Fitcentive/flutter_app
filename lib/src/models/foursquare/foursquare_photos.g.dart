// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_photos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquarePhoto _$FourSquarePhotoFromJson(Map<String, dynamic> json) =>
    FourSquarePhoto(
      json['id'] as String,
      json['url'] as String,
      json['width'] as int,
      json['height'] as int,
      DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FourSquarePhotoToJson(FourSquarePhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'createdAt': instance.createdAt.toIso8601String(),
    };
