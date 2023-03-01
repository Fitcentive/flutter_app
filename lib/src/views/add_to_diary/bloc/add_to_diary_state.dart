import 'package:equatable/equatable.dart';

abstract class AddToDiaryState extends Equatable {
  const AddToDiaryState();

  @override
  List<Object?> get props => [];
}

class AddToDiaryStateInitial extends AddToDiaryState {

  const AddToDiaryStateInitial();
}
