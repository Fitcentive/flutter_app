import 'package:equatable/equatable.dart';

abstract class DetailedExerciseState extends Equatable {
  const DetailedExerciseState();

  @override
  List<Object?> get props => [];
}

class DetailedExerciseStateInitial extends DetailedExerciseState {

  const DetailedExerciseStateInitial();
}
