import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_minutes_per_day.g.dart';

@JsonSerializable()
class ActivityMinutesPerDay extends Equatable {
  final String metricDate;
  final int activityMinutes;


  const ActivityMinutesPerDay(this.metricDate, this.activityMinutes);

  factory ActivityMinutesPerDay.fromJson(Map<String, dynamic> json) => _$ActivityMinutesPerDayFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityMinutesPerDayToJson(this);

  @override
  List<Object?> get props => [
    metricDate,
    activityMinutes,
  ];
}