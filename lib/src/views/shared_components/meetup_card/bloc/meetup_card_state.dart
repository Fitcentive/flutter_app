import 'package:equatable/equatable.dart';

abstract class MeetupCardState extends Equatable {
  const MeetupCardState();

  @override
  List<Object?> get props => [];
}

class MeetupCardStateInitial extends MeetupCardState {

  const MeetupCardStateInitial();
}

class MeetupChatRoomCreated extends MeetupCardState {
  final String chatRoomId;
  // RandomId used with Equatable to force fetch chat room id each time
  final String randomId;

  const MeetupChatRoomCreated({required this.chatRoomId, required this.randomId});

  @override
  List<Object?> get props => [chatRoomId, randomId];
}