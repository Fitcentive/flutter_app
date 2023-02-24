import 'package:equatable/equatable.dart';

abstract class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object?> get props => [];
}

class DiaryStateInitial extends DiaryState {

  const DiaryStateInitial();
}

class DiaryDataLoading extends DiaryState {

  const DiaryDataLoading();
}

class DiaryDataFetched extends DiaryState {

  // todo - add diary data after dfefining backend
  const DiaryDataFetched();

  @override
  List<Object?> get props => [
  ];
}