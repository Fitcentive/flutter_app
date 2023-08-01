import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/progress/progress_insight.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress_insights.g.dart';

@JsonSerializable()
class ProgressInsights extends Equatable {
  final ProgressInsight userWeightProgressInsight;
  final ProgressInsight userDiaryEntryProgressInsight;
  final ProgressInsight userActivityMinutesProgressInsight;

  const ProgressInsights(
      this.userWeightProgressInsight,
      this.userDiaryEntryProgressInsight,
      this.userActivityMinutesProgressInsight
  );

  factory ProgressInsights.fromJson(Map<String, dynamic> json) => _$ProgressInsightsFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressInsightsToJson(this);

  @override
  List<Object?> get props => [
    userWeightProgressInsight,
    userDiaryEntryProgressInsight,
    userActivityMinutesProgressInsight
  ];
}