import 'package:equatable/equatable.dart';

abstract class AddExerciseToDiaryState extends Equatable {
  const AddExerciseToDiaryState();

  @override
  List<Object?> get props => [];
}

class AddExerciseToDiaryStateInitial extends AddExerciseToDiaryState {

  const AddExerciseToDiaryStateInitial();
}

class ExerciseDiaryEntryBeingAdded extends AddExerciseToDiaryState {

  const ExerciseDiaryEntryBeingAdded();
}

class ExerciseDiaryEntryAdded extends AddExerciseToDiaryState {

  const ExerciseDiaryEntryAdded();
}
