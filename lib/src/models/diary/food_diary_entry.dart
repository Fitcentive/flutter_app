import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_diary_entry.g.dart';

@JsonSerializable()
class FoodDiaryEntry extends Equatable {
  final String id;
  final String userId;
  final int foodId;
  final int servingId;
  final double numberOfServings;
  final String mealEntry;
  final DateTime entryDate;
  final DateTime createdAt;
  final DateTime updatedAt;


  const FoodDiaryEntry(
      this.id,
      this.userId,
      this.foodId,
      this.servingId,
      this.numberOfServings,
      this.mealEntry,
      this.entryDate,
      this.createdAt,
      this.updatedAt
  );

  factory FoodDiaryEntry.fromJson(Map<String, dynamic> json) => _$FoodDiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$FoodDiaryEntryToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    foodId,
    servingId,
    numberOfServings,
    mealEntry,
    entryDate,
    createdAt,
    updatedAt
  ];

}

class FoodDiaryEntryCreate extends Equatable {
  final int foodId;
  final int servingId;
  final double numberOfServings;
  final String mealEntry;
  final DateTime entryDate;


  const FoodDiaryEntryCreate({
    required this.foodId,
    required this.servingId,
    required this.numberOfServings,
    required this.mealEntry,
    required this.entryDate
  });

  @override
  List<Object?> get props => [
    foodId,
    servingId,
    numberOfServings,
    mealEntry,
    entryDate
  ];
}

class FoodDiaryEntryUpdate extends Equatable {
  final int servingId;
  final double numberOfServings;
  final DateTime entryDate;


  const FoodDiaryEntryUpdate({
    required this.servingId,
    required this.numberOfServings,
    required this.entryDate
  });

  @override
  List<Object?> get props => [
    servingId,
    numberOfServings,
    entryDate
  ];
}