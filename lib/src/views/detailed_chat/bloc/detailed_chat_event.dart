import 'package:equatable/equatable.dart';

abstract class DetailedChatEvent extends Equatable {
  const DetailedChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomNameChanged extends DetailedChatEvent {
  final String newName;
  final String roomIds;

  const ChatRoomNameChanged({
    required this.newName,
    required this.roomIds
  });

  @override
  List<Object?> get props => [newName, roomIds];
}

class UsersRemovedFromChatRoom extends DetailedChatEvent {
  final List<String> userIds;
  final String currentUserId;
  final String roomId;

  const UsersRemovedFromChatRoom({
    required this.currentUserId,
    required this.userIds,
    required this.roomId
  });

  @override
  List<Object?> get props => [currentUserId, userIds, roomId];
}

class UsersAddedToChatRoom extends DetailedChatEvent {
  final List<String> userIds;
  final String roomId;

  const UsersAddedToChatRoom({
    required this.userIds,
    required this.roomId
  });

  @override
  List<Object?> get props => [userIds, roomId];
}

class MakeUserAdminForChatRoom extends DetailedChatEvent {
  final String userId;
  final String roomId;

  const MakeUserAdminForChatRoom({
    required this.userId,
    required this.roomId
  });

  @override
  List<Object?> get props => [userId, roomId];
}

class RemoveUserAsAdminFromChatRoom extends DetailedChatEvent {
  final String userId;
  final String roomId;

  const RemoveUserAsAdminFromChatRoom({
    required this.userId,
    required this.roomId
  });

  @override
  List<Object?> get props => [userId, roomId];
}
