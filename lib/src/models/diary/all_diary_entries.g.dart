// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_diary_entries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllDiaryEntries _$AllDiaryEntriesFromJson(Map<String, dynamic> json) =>
    AllDiaryEntries(
      (json['cardioWorkouts'] as List<dynamic>)
          .map((e) => CardioDiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['strengthWorkouts'] as List<dynamic>)
          .map((e) => StrengthDiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['foodEntries'] as List<dynamic>)
          .map((e) => FoodDiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AllDiaryEntriesToJson(AllDiaryEntries instance) =>
    <String, dynamic>{
      'cardioWorkouts': instance.cardioWorkouts,
      'strengthWorkouts': instance.strengthWorkouts,
      'foodEntries': instance.foodEntries,
    };
