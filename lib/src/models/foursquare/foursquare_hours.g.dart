// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquareHours _$FourSquareHoursFromJson(Map<String, dynamic> json) =>
    FourSquareHours(
      json['display'] as String?,
      json['isLocalHoliday'] as bool?,
      json['openNow'] as bool?,
      (json['regular'] as List<dynamic>?)
          ?.map(
              (e) => FourSquareRegularHours.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['seasonal'] as List<dynamic>?)
          ?.map((e) =>
              FourSquareSeasonalHours.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FourSquareHoursToJson(FourSquareHours instance) =>
    <String, dynamic>{
      'display': instance.display,
      'isLocalHoliday': instance.isLocalHoliday,
      'openNow': instance.openNow,
      'regular': instance.regular,
      'seasonal': instance.seasonal,
    };
