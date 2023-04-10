import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/chats/chat_message.dart';
import 'package:flutter_app/src/models/chats/chat_room.dart';

abstract class UserChatState extends Equatable {
  const UserChatState();

  @override
  List<Object?> get props => [];
}

class UserChatStateInitial extends UserChatState {
  const UserChatStateInitial();

  @override
  List<Object?> get props => [];
}

class HistoricalChatsLoading extends UserChatState {

  const HistoricalChatsLoading();

  @override
  List<Object?> get props => [];

}

class HistoricalChatsFetched extends UserChatState {
  final String roomId;
  final List<ChatMessage> messages;
  final bool doesNextPageExist;
  final ChatRoom currentChatRoom;

  const HistoricalChatsFetched({
    required this.roomId,
    required this.messages,
    required this.doesNextPageExist,
    required this.currentChatRoom,
  });

  @override
  List<Object?> get props => [roomId, messages, doesNextPageExist, currentChatRoom];
}