import 'package:equatable/equatable.dart';

abstract class ChatHomeEvent extends Equatable {
  const ChatHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserRooms extends ChatHomeEvent {
  final String userId;
  final int limit;
  final int offset;

  const FetchUserRooms({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}

class FetchMoreUserRooms extends ChatHomeEvent {
  final String userId;
  final int limit;

  const FetchMoreUserRooms({
    required this.userId,
    required this.limit,
  });

  @override
  List<Object?> get props => [userId, limit];
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

class TrackViewChatHomeEvent extends ChatHomeEvent {

  const TrackViewChatHomeEvent();

  @override
  List<Object?> get props => [];
}