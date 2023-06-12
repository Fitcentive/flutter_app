import 'package:equatable/equatable.dart';

abstract class ExerciseDiaryEvent extends Equatable {
  const ExerciseDiaryEvent();

  @override
  List<Object?> get props => [];
}

class FetchExerciseDiaryEntryInfo extends ExerciseDiaryEvent {
  final String userId;
  final String workoutId;

  const FetchExerciseDiaryEntryInfo({
    required this.userId,
    required this.workoutId
  });

  @override
  List<Object?> get props => [
    userId,
    workoutId
  ];
}

class ExerciseDiaryEntryUpdated extends ExerciseDiaryEvent {
  // todo - fill this in
}