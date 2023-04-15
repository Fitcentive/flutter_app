import 'package:equatable/equatable.dart';

abstract class DetailedChatEvent extends Equatable {
  const DetailedChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomNameChanged extends DetailedChatEvent {
  final String newName;
  final String roomId;

  const ChatRoomNameChanged({
    required this.newName,
    required this.roomId
  });

  @override
  List<Object?> get props => [newName, roomId];
}

class UserRemovedFromChatRoom extends DetailedChatEvent {
  final String userId;
  final String roomId;

  const UserRemovedFromChatRoom({
    required this.userId,
    required this.roomId
  });

  @override
  List<Object?> get props => [userId, roomId];
}

class UserAddedToChatRoom extends DetailedChatEvent {
  final String userId;
  final String roomId;

  const UserAddedToChatRoom({
    required this.userId,
    required this.roomId
  });

  @override
  List<Object?> get props => [userId, roomId];
}
