import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';

abstract class AddFoodToDiaryEvent extends Equatable {
  const AddFoodToDiaryEvent();

  @override
  List<Object?> get props => [];
}

class AddFoodEntryToDiary extends AddFoodToDiaryEvent {
  final String userId;
  final FoodDiaryEntryCreate newEntry;

  const AddFoodEntryToDiary({
    required this.userId,
    required this.newEntry
  });

  @override
  List<Object?> get props => [userId, newEntry];

}
