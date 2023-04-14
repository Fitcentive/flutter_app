import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class ChatHomeState extends Equatable {
  const ChatHomeState();
}

class ChatStateInitial extends ChatHomeState {
  const ChatStateInitial();

  @override
  List<Object?> get props => [];
}

class UserRoomsLoading extends ChatHomeState {

  const UserRoomsLoading();

  @override
  List<Object?> get props => [];

}

class UserRoomsLoaded extends ChatHomeState {
  final List<ChatRoomWithMostRecentMessage> filteredRooms;
  final List<ChatRoomWithMostRecentMessage> rooms;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const UserRoomsLoaded({
    required this.rooms,
    required this.filteredRooms,
    required this.userIdProfileMap
  });

  @override
  List<Object?> get props => [rooms, userIdProfileMap, filteredRooms];
}