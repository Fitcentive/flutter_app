import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';

abstract class ExerciseDiaryEvent extends Equatable {
  const ExerciseDiaryEvent();

  @override
  List<Object?> get props => [];
}

class FetchExerciseDiaryEntryInfo extends ExerciseDiaryEvent {
  final String userId;
  final String diaryEntryId;
  final bool isCardio;
  final String workoutId;

  const FetchExerciseDiaryEntryInfo({
    required this.userId,
    required this.diaryEntryId,
    required this.isCardio,
    required this.workoutId
  });

  @override
  List<Object?> get props => [
    userId,
    workoutId,
    isCardio,
    diaryEntryId,
  ];
}

class StrengthExerciseDiaryEntryUpdated extends ExerciseDiaryEvent {
  final String userId;
  final String strengthDiaryEntryId;
  final StrengthDiaryEntryUpdate entry;

  const StrengthExerciseDiaryEntryUpdated({
    required this.userId,
    required this.strengthDiaryEntryId,
    required this.entry
  });

  @override
  List<Object?> get props => [userId, strengthDiaryEntryId, entry];

}

class CardioExerciseDiaryEntryUpdated extends ExerciseDiaryEvent {
  final String userId;
  final String cardioDiaryEntryId;
  final CardioDiaryEntryUpdate entry;

  const CardioExerciseDiaryEntryUpdated({
    required this.userId,
    required this.cardioDiaryEntryId,
    required this.entry
  });

  @override
  List<Object?> get props => [userId, cardioDiaryEntryId, entry];

}