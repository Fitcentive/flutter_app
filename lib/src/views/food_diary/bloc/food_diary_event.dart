import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';

abstract class FoodDiaryEvent extends Equatable {
  const FoodDiaryEvent();

  @override
  List<Object?> get props => [];
}

class FetchFoodDiaryEntryInfo extends FoodDiaryEvent {
  final String userId;
  final String diaryEntryId;
  final int foodId;

  const FetchFoodDiaryEntryInfo({
    required this.userId,
    required this.diaryEntryId,
    required this.foodId,
  });

  @override
  List<Object?> get props => [
    userId,
    foodId,
    diaryEntryId,
  ];
}

class FoodDiaryEntryUpdated extends FoodDiaryEvent {
  final String userId;
  final String foodDiaryEntryId;
  final FoodDiaryEntryUpdate entry;

  const FoodDiaryEntryUpdated({
    required this.userId,
    required this.foodDiaryEntryId,
    required this.entry
  });

  @override
  List<Object?> get props => [userId, foodDiaryEntryId, entry];

}

