import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();

  @override
  List<Object?> get props => [];
}

class FetchDiaryInfo extends DiaryEvent {
  final String userId;
  final DateTime diaryDate;

  const FetchDiaryInfo({
    required this.userId,
    required this.diaryDate
  });

  @override
  List<Object?> get props => [
    userId,
    diaryDate
  ];
}

class RemoveFoodDiaryEntryFromDiary extends DiaryEvent {
  final String userId;
  final String foodDiaryEntryId;

  const RemoveFoodDiaryEntryFromDiary({
    required this.userId,
    required this.foodDiaryEntryId
  });

  @override
  List<Object?> get props => [
    userId,
    foodDiaryEntryId
  ];
}

class RemoveCardioDiaryEntryFromDiary extends DiaryEvent {
  final String userId;
  final String cardioDiaryEntryId;

  const RemoveCardioDiaryEntryFromDiary({
    required this.userId,
    required this.cardioDiaryEntryId
  });

  @override
  List<Object?> get props => [
    userId,
    cardioDiaryEntryId
  ];
}

class RemoveStrengthDiaryEntryFromDiary extends DiaryEvent {
  final String userId;
  final String strengthDiaryEntryId;

  const RemoveStrengthDiaryEntryFromDiary({
    required this.userId,
    required this.strengthDiaryEntryId
  });

  @override
  List<Object?> get props => [
    userId,
    strengthDiaryEntryId
  ];
}

class UserFitnessProfileUpdated extends DiaryEvent {
  final FitnessUserProfile fitnessUserProfile;

  const UserFitnessProfileUpdated({
    required this.fitnessUserProfile,
  });

  @override
  List<Object?> get props => [
    fitnessUserProfile,
  ];
}