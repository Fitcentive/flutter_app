import 'package:equatable/equatable.dart';

abstract class MeetupHomeEvent extends Equatable {
  const MeetupHomeEvent();

  @override
  List<Object?> get props => [];
}

class TraceViewMeetupHomeEvent extends MeetupHomeEvent {

  const TraceViewMeetupHomeEvent();

  @override
  List<Object?> get props => [];

}

class FetchUserMeetupData extends MeetupHomeEvent {
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


class FetchMoreUserMeetupData extends MeetupHomeEvent {
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


class DeleteMeetupForUser extends MeetupHomeEvent {
  final String currentUserId;
  final String meetupId;

  const DeleteMeetupForUser({
    required this.currentUserId,
    required this.meetupId
  });

  @override
  List<Object?> get props => [currentUserId, meetupId];
}