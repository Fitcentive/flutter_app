import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';

abstract class ActivitySearchState extends Equatable {
  const ActivitySearchState();

  @override
  List<Object?> get props => [];
}

class ActivitySearchStateInitial extends ActivitySearchState {

  const ActivitySearchStateInitial();
}

class ActivityDataLoading extends ActivitySearchState {

  const ActivityDataLoading();
}

class ActivityDataFetched extends ActivitySearchState {
  final List<ExerciseDefinition> allExerciseInfo;
  final List<ExerciseDefinition> filteredExerciseInfo;

  const ActivityDataFetched({
    required this.allExerciseInfo,
    required this.filteredExerciseInfo,
  });

  @override
  List<Object?> get props => [
    allExerciseInfo,
    filteredExerciseInfo
  ];
}