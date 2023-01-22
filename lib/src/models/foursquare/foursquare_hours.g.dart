// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquareHours _$FourSquareHoursFromJson(Map<String, dynamic> json) =>
    FourSquareHours(
      json['display'] as String,
      json['isLocalHoliday'] as bool,
      json['openNow'] as bool,
      FourSquareRegularHours.fromJson(json['regular'] as Map<String, dynamic>),
      FourSquareRegularHours.fromJson(json['seasonal'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FourSquareHoursToJson(FourSquareHours instance) =>
    <String, dynamic>{
      'display': instance.display,
      'isLocalHoliday': instance.isLocalHoliday,
      'openNow': instance.openNow,
      'regular': instance.regular,
      'seasonal': instance.seasonal,
    };
