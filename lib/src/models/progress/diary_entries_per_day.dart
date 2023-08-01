import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'diary_entries_per_day.g.dart';

@JsonSerializable()
class DiaryEntriesPerDay extends Equatable {
  final String metricDate;
  final int entryCount;

  const DiaryEntriesPerDay(this.metricDate, this.entryCount);

  factory DiaryEntriesPerDay.fromJson(Map<String, dynamic> json) => _$DiaryEntriesPerDayFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryEntriesPerDayToJson(this);

  @override
  List<Object?> get props => [
    metricDate,
    entryCount,
  ];
}