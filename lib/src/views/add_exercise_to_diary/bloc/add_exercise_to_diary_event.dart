import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';

abstract class AddExerciseToDiaryEvent extends Equatable {
  const AddExerciseToDiaryEvent();

  @override
  List<Object?> get props => [];
}

class AddCardioEntryToDiary extends AddExerciseToDiaryEvent {
  final String userId;
  final String? associatedMeetupId;
  final CardioDiaryEntryCreate newEntry;

  const AddCardioEntryToDiary({
    required this.userId,
    required this.associatedMeetupId,
    required this.newEntry
  });

  @override
  List<Object?> get props => [userId, newEntry, associatedMeetupId];

}


class AddStrengthEntryToDiary extends AddExerciseToDiaryEvent {
  final String userId;
  final String? associatedMeetupId;
  final StrengthDiaryEntryCreate newEntry;

  const AddStrengthEntryToDiary({
    required this.userId,
    required this.associatedMeetupId,
    required this.newEntry
  });

  @override
  List<Object?> get props => [userId, newEntry, associatedMeetupId];

}
