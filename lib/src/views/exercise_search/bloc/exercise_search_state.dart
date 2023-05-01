import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';

abstract class ExerciseSearchState extends Equatable {
  const ExerciseSearchState();

  @override
  List<Object?> get props => [];
}

class ExerciseSearchStateInitial extends ExerciseSearchState {

  const ExerciseSearchStateInitial();
}

class ExerciseDataLoading extends ExerciseSearchState {

  const ExerciseDataLoading();
}

class ExerciseDataFetched extends ExerciseSearchState {
  final List<ExerciseDefinition> allExerciseInfo;
  final List<ExerciseDefinition> filteredExerciseInfo;
  final List<String> recentlyViewedWorkoutIds;

  const ExerciseDataFetched({
    required this.allExerciseInfo,
    required this.filteredExerciseInfo,
    required this.recentlyViewedWorkoutIds,
  });

  @override
  List<Object?> get props => [
    allExerciseInfo,
    filteredExerciseInfo,
    recentlyViewedWorkoutIds,
  ];
}