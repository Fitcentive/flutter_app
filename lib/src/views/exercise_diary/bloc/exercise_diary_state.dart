import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';

abstract class ExerciseDiaryState extends Equatable {
  const ExerciseDiaryState();

  @override
  List<Object?> get props => [];
}

class ExerciseDiaryStateInitial extends ExerciseDiaryState {

  const ExerciseDiaryStateInitial();
}

class ExerciseDiaryDataLoading extends ExerciseDiaryState {

  const ExerciseDiaryDataLoading();
}

class ExerciseDiaryDataLoaded extends ExerciseDiaryState {
  final ExerciseDefinition exerciseDefinition;

  const ExerciseDiaryDataLoaded({required this.exerciseDefinition});

  @override
  List<Object?> get props => [exerciseDefinition];
}