import 'package:equatable/equatable.dart';

abstract class DetailedExerciseEvent extends Equatable {
  const DetailedExerciseEvent();

  @override
  List<Object?> get props => [];
}

class AddCurrentExerciseToUserMostRecentlyViewed extends DetailedExerciseEvent {
  final String currentUserId;
  final String currentExerciseId;

  const AddCurrentExerciseToUserMostRecentlyViewed({
    required this.currentUserId,
    required this.currentExerciseId
  });

  @override
  List<Object?> get props => [currentUserId, currentExerciseId];
}