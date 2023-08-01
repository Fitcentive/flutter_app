// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entries_per_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryEntriesPerDay _$DiaryEntriesPerDayFromJson(Map<String, dynamic> json) =>
    DiaryEntriesPerDay(
      json['metricDate'] as String,
      json['entryCount'] as int,
    );

Map<String, dynamic> _$DiaryEntriesPerDayToJson(DiaryEntriesPerDay instance) =>
    <String, dynamic>{
      'metricDate': instance.metricDate,
      'entryCount': instance.entryCount,
    };
