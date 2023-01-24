import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_regular_hours.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_seasonal_hours.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_hours.g.dart';

@JsonSerializable()
class FourSquareHours extends Equatable {
  final String? display;
  final bool? isLocalHoliday;
  final bool? openNow;
  final List<FourSquareRegularHours>? regular;
  final List<FourSquareSeasonalHours>? seasonal;

  const FourSquareHours(this.display, this.isLocalHoliday, this.openNow, this.regular, this.seasonal);

  factory FourSquareHours.fromJson(Map<String, dynamic> json) => _$FourSquareHoursFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareHoursToJson(this);

  @override
  List<Object?> get props => [
    display,
    isLocalHoliday,
    openNow,
    regular,
    seasonal,
  ];
}