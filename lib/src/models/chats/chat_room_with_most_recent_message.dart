import 'package:equatable/equatable.dart';

class ChatRoomWithMostRecentMessage extends Equatable {
  final String roomId;
  final List<String> userIds;
  final String mostRecentMessage;

  const ChatRoomWithMostRecentMessage({required this.roomId, required this.userIds, required  this.mostRecentMessage});

  @override
  List<Object> get props => [roomId, userIds, mostRecentMessage];
}