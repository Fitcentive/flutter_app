import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'all_diary_entries.g.dart';

@JsonSerializable()
class AllDiaryEntries extends Equatable {
  final List<CardioDiaryEntry> cardioWorkouts;
  final List<StrengthDiaryEntry> strengthWorkouts;
  final List <FoodDiaryEntry> foodEntries;

  const AllDiaryEntries(
      this.cardioWorkouts,
      this.strengthWorkouts,
      this.foodEntries
  );

  factory AllDiaryEntries.fromJson(Map<String, dynamic> json) => _$AllDiaryEntriesFromJson(json);

  Map<String, dynamic> toJson() => _$AllDiaryEntriesToJson(this);


  @override
  List<Object?> get props => [
    cardioWorkouts,
    strengthWorkouts,
    foodEntries,
  ];
}