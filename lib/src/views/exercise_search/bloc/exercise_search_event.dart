import 'package:equatable/equatable.dart';

abstract class ExerciseSearchEvent extends Equatable {
  const ExerciseSearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllExerciseInfo extends ExerciseSearchEvent {
  final String currentUserId;

  const FetchAllExerciseInfo({
    required this.currentUserId
  });

  @override
  List<Object?> get props => [currentUserId];
}

class FilterSearchQueryChanged extends ExerciseSearchEvent {
  final String searchQuery;

  const FilterSearchQueryChanged({ required this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}
