import 'package:equatable/equatable.dart';

abstract class MenuNavigationEvent extends Equatable {
  const MenuNavigationEvent();
}

class MenuItemChosen extends MenuNavigationEvent {
  final String selectedMenuItem;
  final String currentUserId;
  final String? preSelectedDiaryDateString;

  const MenuItemChosen({
    required this.selectedMenuItem,
    required this.currentUserId,
    this.preSelectedDiaryDateString,
  });

  @override
  List<Object?> get props => [selectedMenuItem, currentUserId, preSelectedDiaryDateString];
}

class MarkUserAppTutorialAsComplete extends MenuNavigationEvent {
  final String currentUserId;

  const MarkUserAppTutorialAsComplete({
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [currentUserId];
}


class NewIncomingChatMessageForRoom extends MenuNavigationEvent {
  final String roomId;

  const NewIncomingChatMessageForRoom({
    required this.roomId,
  });

  @override
  List<Object?> get props => [roomId];
}

class ReInitWebSockets extends MenuNavigationEvent {
  final String currentUserId;

  const ReInitWebSockets({
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [currentUserId];
}