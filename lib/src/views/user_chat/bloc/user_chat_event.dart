import 'package:equatable/equatable.dart';

abstract class UserChatEvent extends Equatable {
  const UserChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectWebsocketAndFetchHistoricalChats extends UserChatEvent {
  final String roomId;
  final String currentUserId;

  const ConnectWebsocketAndFetchHistoricalChats({required this.roomId, required this.currentUserId});

  @override
  List<Object?> get props => [roomId, currentUserId];
}

class AddMessageToChatRoom extends UserChatEvent {
  final String roomId;
  final String text;

  const AddMessageToChatRoom({required this.roomId, required this.text});

  @override
  List<Object?> get props => [roomId, text];
}

class UpdateIncomingMessageIntoChatRoom extends UserChatEvent {
  final String userId;
  final String text;

  const UpdateIncomingMessageIntoChatRoom({required this.userId, required this.text});

  @override
  List<Object?> get props => [userId, text];
}

