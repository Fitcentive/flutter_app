import 'package:equatable/equatable.dart';

abstract class MeetupHomeEvent extends Equatable {
  const MeetupHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserMeetupData extends MeetupHomeEvent {
  final String userId;

  const FetchUserMeetupData(this.userId);

  @override
  List<Object?> get props => [userId];
}


class FetchMoreUserMeetupData extends MeetupHomeEvent {
  final String userId;

  const FetchMoreUserMeetupData(this.userId);

  @override
  List<Object?> get props => [userId];
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