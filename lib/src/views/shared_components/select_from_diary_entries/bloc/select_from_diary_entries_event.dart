import 'package:equatable/equatable.dart';

abstract class SelectFromDiaryEntriesEvent extends Equatable {
  const SelectFromDiaryEntriesEvent();

  @override
  List<Object?> get props => [];
}

class SelectFromDiaryEntriesFetchInfoEvent extends SelectFromDiaryEntriesEvent {
  final String userId;
  final DateTime diaryDate;

  const SelectFromDiaryEntriesFetchInfoEvent({
    required this.userId,
    required this.diaryDate
  });

  @override
  List<Object?> get props => [
    userId,
    diaryDate
  ];
}