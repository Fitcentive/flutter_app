import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress_insight.g.dart';

@JsonSerializable()
class ProgressInsight extends Equatable {
  final String insight;
  final int level;

  factory ProgressInsight.fromJson(Map<String, dynamic> json) => _$ProgressInsightFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressInsightToJson(this);

  const ProgressInsight(this.insight, this.level);

  @override
  List<Object?> get props => [
    insight,
    level
  ];
}