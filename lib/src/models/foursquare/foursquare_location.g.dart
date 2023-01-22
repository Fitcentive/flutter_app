// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquareLocation _$FourSquareLocationFromJson(Map<String, dynamic> json) =>
    FourSquareLocation(
      json['address'] as String,
      json['country'] as String,
      json['formattedAddress'] as String,
      json['locality'] as String,
      json['region'] as String,
    );

Map<String, dynamic> _$FourSquareLocationToJson(FourSquareLocation instance) =>
    <String, dynamic>{
      'address': instance.address,
      'country': instance.country,
      'formattedAddress': instance.formattedAddress,
      'locality': instance.locality,
      'region': instance.region,
    };
