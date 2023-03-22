import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';

abstract class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object?> get props => [];
}

class DiaryStateInitial extends DiaryState {

  const DiaryStateInitial();
}

class DiaryDataLoading extends DiaryState {

  const DiaryDataLoading();
}

class DiaryDataFetched extends DiaryState {
  final List<StrengthDiaryEntry> strengthDiaryEntries;
  final List<CardioDiaryEntry> cardioDiaryEntries;
  final List<FoodDiaryEntry> foodDiaryEntries;

  const DiaryDataFetched({
    required this.strengthDiaryEntries,
    required this.cardioDiaryEntries,
    required this.foodDiaryEntries,
});

  @override
  List<Object?> get props => [
    strengthDiaryEntries,
    cardioDiaryEntries,
    foodDiaryEntries,
  ];
}