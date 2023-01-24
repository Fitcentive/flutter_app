// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foursquare_seasonal_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FourSquareSeasonalHours _$FourSquareSeasonalHoursFromJson(
        Map<String, dynamic> json) =>
    FourSquareSeasonalHours(
      json['closed'] as bool?,
      json['endDate'] as String?,
      json['startDate'] as String?,
      (json['hours'] as List<dynamic>?)
          ?.map(
              (e) => FourSquareRegularHours.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FourSquareSeasonalHoursToJson(
        FourSquareSeasonalHours instance) =>
    <String, dynamic>{
      'closed': instance.closed,
      'endDate': instance.endDate,
      'startDate': instance.startDate,
      'hours': instance.hours,
    };
