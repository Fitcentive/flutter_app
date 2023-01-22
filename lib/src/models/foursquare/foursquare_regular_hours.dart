import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_regular_hours.g.dart';

@JsonSerializable()
class FourSquareRegularHours extends Equatable {
  final String close;
  final String day;
  final String open;

  const FourSquareRegularHours(this.close, this.day, this.open);

  factory FourSquareRegularHours.fromJson(Map<String, dynamic> json) => _$FourSquareRegularHoursFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareRegularHoursToJson(this);

  @override
  List<Object?> get props => [
    close,
    day,
    open,
  ];
}