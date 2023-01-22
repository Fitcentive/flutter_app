// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquareResult _$FourSquareResultFromJson(Map<String, dynamic> json) =>
    FourSquareResult(
      json['fsqId'] as String,
      (json['categories'] as List<dynamic>)
          .map((e) => FourSquareCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['distance'] as int,
      FourSquareGeoCodes.fromJson(json['geocodes'] as Map<String, dynamic>),
      json['link'] as String,
      FourSquareLocation.fromJson(json['location'] as Map<String, dynamic>),
      json['name'] as String,
      json['price'] as int?,
      (json['rating'] as num?)?.toDouble(),
      json['tel'] as String?,
      json['website'] as String?,
      json['socialMedia'] == null
          ? null
          : FourSquareSocialMedia.fromJson(
              json['socialMedia'] as Map<String, dynamic>),
      FourSquareHours.fromJson(json['hours'] as Map<String, dynamic>),
      (json['photos'] as List<dynamic>?)
          ?.map((e) => FourSquarePhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FourSquareResultToJson(FourSquareResult instance) =>
    <String, dynamic>{
      'fsqId': instance.fsqId,
      'categories': instance.categories,
      'distance': instance.distance,
      'geocodes': instance.geocodes,
      'link': instance.link,
      'location': instance.location,
      'name': instance.name,
      'price': instance.price,
      'rating': instance.rating,
      'tel': instance.tel,
      'website': instance.website,
      'socialMedia': instance.socialMedia,
      'hours': instance.hours,
      'photos': instance.photos,
    };
