// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_weight_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserWeightMetrics _$UserWeightMetricsFromJson(Map<String, dynamic> json) =>
    UserWeightMetrics(
      json['userId'] as String,
      json['metricDate'] as String,
      (json['weightInLbs'] as num).toDouble(),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserWeightMetricsToJson(UserWeightMetrics instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'metricDate': instance.metricDate,
      'weightInLbs': instance.weightInLbs,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
