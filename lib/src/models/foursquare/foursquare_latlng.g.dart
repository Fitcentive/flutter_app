// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_latlng.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquareLatLng _$FourSquareLatLngFromJson(Map<String, dynamic> json) =>
    FourSquareLatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$FourSquareLatLngToJson(FourSquareLatLng instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
