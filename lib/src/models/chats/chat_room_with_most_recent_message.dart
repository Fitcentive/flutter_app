import 'package:equatable/equatable.dart';

class ChatRoomWithMostRecentMessage extends Equatable {
  final String roomId;
  final List<String> userIds;
  final String mostRecentMessage;
  final DateTime mostRecentMessageTime;
  final String roomName;
  final bool isGroupChat;

  const ChatRoomWithMostRecentMessage({
    required this.roomId,
    required this.userIds,
    required  this.mostRecentMessage,
    required  this.mostRecentMessageTime,
    required this.roomName,
    required this.isGroupChat,
  });

  @override
  List<Object> get props => [roomId, userIds, mostRecentMessage, roomName, isGroupChat, mostRecentMessageTime];
}