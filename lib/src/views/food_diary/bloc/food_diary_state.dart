import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';

abstract class FoodDiaryState extends Equatable {
  const FoodDiaryState();

  @override
  List<Object?> get props => [];
}

class FoodDiaryStateInitial extends FoodDiaryState {

  const FoodDiaryStateInitial();
}

class FoodDiaryDataLoading extends FoodDiaryState {

  const FoodDiaryDataLoading();
}

class FoodDiaryDataLoaded extends FoodDiaryState {
  final Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition;
  final FoodDiaryEntry diaryEntry;

  const FoodDiaryDataLoaded({
    required this.foodDefinition,
    required this.diaryEntry,
  });

  @override
  List<Object?> get props => [foodDefinition, diaryEntry];
}

class FoodEntryUpdatedAndReadyToPop extends FoodDiaryState {

  const FoodEntryUpdatedAndReadyToPop();

  @override
  List<Object?> get props => [];
}