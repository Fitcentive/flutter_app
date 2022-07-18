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