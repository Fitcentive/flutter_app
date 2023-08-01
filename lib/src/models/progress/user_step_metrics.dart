import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_step_metrics.g.dart';

@JsonSerializable()
class UserStepMetrics extends Equatable {
  final String userId;
  final String metricDate;
  final int stepsTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserStepMetrics(
      this.userId,
      this.metricDate,
      this.stepsTaken,
      this.createdAt,
      this.updatedAt
  );

  factory UserStepMetrics.fromJson(Map<String, dynamic> json) => _$UserStepMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$UserStepMetricsToJson(this);

  @override
  List<Object?> get props => [
    userId,
    metricDate,
    stepsTaken,
    createdAt,
    updatedAt
  ];
}