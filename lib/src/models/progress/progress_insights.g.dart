// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_insights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressInsights _$ProgressInsightsFromJson(Map<String, dynamic> json) =>
    ProgressInsights(
      ProgressInsight.fromJson(
          json['userWeightProgressInsight'] as Map<String, dynamic>),
      ProgressInsight.fromJson(
          json['userDiaryEntryProgressInsight'] as Map<String, dynamic>),
      ProgressInsight.fromJson(
          json['userActivityMinutesProgressInsight'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProgressInsightsToJson(ProgressInsights instance) =>
    <String, dynamic>{
      'userWeightProgressInsight': instance.userWeightProgressInsight,
      'userDiaryEntryProgressInsight': instance.userDiaryEntryProgressInsight,
      'userActivityMinutesProgressInsight':
          instance.userActivityMinutesProgressInsight,
    };
