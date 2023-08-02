import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_weight_metrics.g.dart';

@JsonSerializable()
class UserWeightMetrics extends Equatable {
  final String userId;
  final String metricDate;
  final double weightInLbs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserWeightMetrics(
      this.userId,
      this.metricDate,
      this.weightInLbs,
      this.createdAt,
      this.updatedAt
      );

  factory UserWeightMetrics.fromJson(Map<String, dynamic> json) => _$UserWeightMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$UserWeightMetricsToJson(this);

  @override
  List<Object?> get props => [
    userId,
    metricDate,
    weightInLbs,
    createdAt,
    updatedAt
  ];
}