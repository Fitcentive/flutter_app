// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_diary_entries_for_month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllDiaryEntriesForMonth _$AllDiaryEntriesForMonthFromJson(
        Map<String, dynamic> json) =>
    AllDiaryEntriesForMonth(
      (json['entries'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, AllDiaryEntries.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$AllDiaryEntriesForMonthToJson(
        AllDiaryEntriesForMonth instance) =>
    <String, dynamic>{
      'entries': instance.entries,
    };
