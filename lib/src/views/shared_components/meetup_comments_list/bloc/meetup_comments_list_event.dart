import 'package:equatable/equatable.dart';

abstract class MeetupCommentsListEvent extends Equatable {
  const MeetupCommentsListEvent();
}

class FetchMeetupCommentsRequested extends MeetupCommentsListEvent {
  final String meetupId;
  final String currentUserId;

  const FetchMeetupCommentsRequested({required this.meetupId, required this.currentUserId});

  @override
  List<Object> get props => [meetupId, currentUserId];
}

class AddNewMeetupComment extends MeetupCommentsListEvent {
  final String meetupId;
  final String userId;
  final String comment;

  const AddNewMeetupComment({
    required this.meetupId,
    required this.userId,
    required this.comment,
  });

  @override
  List<Object> get props => [comment, meetupId, comment];
}