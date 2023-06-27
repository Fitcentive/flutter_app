import 'package:equatable/equatable.dart';

abstract class SelectFromMeetupsEvent extends Equatable {
  const SelectFromMeetupsEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserMeetupData extends SelectFromMeetupsEvent {
  final String userId;
  final String? selectedFilterByOption;
  final String? selectedStatusOption;


  const FetchUserMeetupData({
    required this.userId,
    this.selectedFilterByOption,
    this.selectedStatusOption
  });

  @override
  List<Object?> get props => [userId, selectedStatusOption, selectedFilterByOption];
}


class FetchMoreUserMeetupData extends SelectFromMeetupsEvent {
  final String userId;
  final String? selectedFilterByOption;
  final String? selectedStatusOption;


  const FetchMoreUserMeetupData({
    required this.userId,
    this.selectedFilterByOption,
    this.selectedStatusOption
  });

  @override
  List<Object?> get props => [userId, selectedFilterByOption, selectedStatusOption];
}
