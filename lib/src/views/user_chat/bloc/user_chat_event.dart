import 'package:equatable/equatable.dart';

abstract class UserChatEvent extends Equatable {
  const UserChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchHistoricalChats extends UserChatEvent {
  final String roomId;

  const FetchHistoricalChats({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

