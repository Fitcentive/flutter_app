import 'package:equatable/equatable.dart';

abstract class ExerciseSearchEvent extends Equatable {
  const ExerciseSearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllExerciseInfo extends ExerciseSearchEvent {

  const FetchAllExerciseInfo();

  @override
  List<Object?> get props => [];
}

class FilterSearchQueryChanged extends ExerciseSearchEvent {
  final String searchQuery;

  const FilterSearchQueryChanged({ required this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}
