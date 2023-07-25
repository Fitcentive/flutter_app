import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/diary/user_steps_data.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';

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
  final FitnessUserProfile? fitnessUserProfile;
  final List<StrengthDiaryEntry> strengthDiaryEntries;
  final List<CardioDiaryEntry> cardioDiaryEntries;
  final List<FoodDiaryEntry> foodDiaryEntriesRaw;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> foodDiaryEntries;
  final UserStepsData? userStepsData;

  const DiaryDataFetched({
    required this.strengthDiaryEntries,
    required this.cardioDiaryEntries,
    required this.foodDiaryEntriesRaw,
    required this.foodDiaryEntries,
    required this.fitnessUserProfile,
    required this.userStepsData,
});

  @override
  List<Object?> get props => [
    strengthDiaryEntries,
    cardioDiaryEntries,
    foodDiaryEntriesRaw,
    foodDiaryEntries,
    fitnessUserProfile,
    userStepsData
  ];
}