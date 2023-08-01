// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_step_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStepMetrics _$UserStepMetricsFromJson(Map<String, dynamic> json) =>
    UserStepMetrics(
      json['userId'] as String,
      json['metricDate'] as String,
      json['stepsTaken'] as int,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserStepMetricsToJson(UserStepMetrics instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'metricDate': instance.metricDate,
      'stepsTaken': instance.stepsTaken,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
