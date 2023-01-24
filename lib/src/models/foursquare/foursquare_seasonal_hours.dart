import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_regular_hours.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_seasonal_hours.g.dart';

@JsonSerializable()
class FourSquareSeasonalHours extends Equatable {
  final bool? closed;
  final String? endDate;
  final String? startDate;
  final List<FourSquareRegularHours>? hours;

  const FourSquareSeasonalHours(this.closed, this.endDate, this.startDate, this.hours);

  factory FourSquareSeasonalHours.fromJson(Map<String, dynamic> json) => _$FourSquareSeasonalHoursFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareSeasonalHoursToJson(this);

  @override
  List<Object?> get props => [
    closed,
    endDate,
    startDate,
    hours,
  ];
}