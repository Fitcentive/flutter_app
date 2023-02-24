import 'package:equatable/equatable.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();

  @override
  List<Object?> get props => [];
}

class FetchDiaryInfo extends DiaryEvent {
  final DateTime diaryDate;

  const FetchDiaryInfo({
    required this.diaryDate
  });

  @override
  List<Object?> get props => [
    diaryDate
  ];
}