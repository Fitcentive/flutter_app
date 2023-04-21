import 'package:equatable/equatable.dart';

abstract class ChatHomeEvent extends Equatable {
  const ChatHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserRooms extends ChatHomeEvent {
  final String userId;

  const FetchUserRooms({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class FilterSearchQueryChanged extends ChatHomeEvent {
  final String query;

  const FilterSearchQueryChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

class ChatRoomHasNewMessage extends ChatHomeEvent {
  final String roomId;

  const ChatRoomHasNewMessage({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}