import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/chats/chat_message.dart';

abstract class UserChatState extends Equatable {
  const UserChatState();
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


  const HistoricalChatsFetched({required this.roomId, required this.messages});

  @override
  List<Object?> get props => [roomId, messages];
}