import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:json_annotation/json_annotation.dart';

part 'all_diary_entries_for_month.g.dart';

@JsonSerializable()
class AllDiaryEntriesForMonth extends Equatable {
  final Map<String, AllDiaryEntries> entries;

  const AllDiaryEntriesForMonth(
      this.entries,
      );

  factory AllDiaryEntriesForMonth.fromJson(Map<String, dynamic> json) => _$AllDiaryEntriesForMonthFromJson(json);

  Map<String, dynamic> toJson() => _$AllDiaryEntriesForMonthToJson(this);


  @override
  List<Object?> get props => [
    entries,
  ];
}