import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/meetups/detailed_meetup.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

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
  final Either<CardioDiaryEntry, StrengthDiaryEntry> diaryEntry;

  final DetailedMeetup? associatedMeetup;
  final Map<String, PublicUserProfile>? associatedUserIdProfileMap;

  const ExerciseDiaryDataLoaded({
    required this.exerciseDefinition,
    required this.diaryEntry,
    this.associatedMeetup,
    this.associatedUserIdProfileMap,
  });

  @override
  List<Object?> get props => [exerciseDefinition, diaryEntry, associatedMeetup, associatedUserIdProfileMap];
}

class ExerciseEntryUpdatedAndReadyToPop extends ExerciseDiaryState {

  const ExerciseEntryUpdatedAndReadyToPop();

  @override
  List<Object?> get props => [];
}