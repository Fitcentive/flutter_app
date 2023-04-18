import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';

abstract class MeetupCardEvent extends Equatable {
  const MeetupCardEvent();

  @override
  List<Object?> get props => [];
}

class CreateChatRoomForMeetup extends MeetupCardEvent {
  final Meetup meetup;
  final String roomName;
  final List<String> participants;

  const CreateChatRoomForMeetup({
    required this.meetup,
    required this.roomName,
    required this.participants
  });

  @override
  List<Object?> get props => [meetup, roomName, participants];
}

// This is used when meetup has < 3 participants
class GetDirectMessagePrivateChatRoomForMeetup extends MeetupCardEvent {
  final Meetup meetup;
  final String currentUserProfileId;
  final List<String> participants;

  const GetDirectMessagePrivateChatRoomForMeetup({
    required this.meetup,
    required this.currentUserProfileId,
    required this.participants
  });

  @override
  List<Object?> get props => [meetup, currentUserProfileId, participants];
}