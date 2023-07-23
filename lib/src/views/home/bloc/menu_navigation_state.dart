import 'package:equatable/equatable.dart';

abstract class MenuNavigationState extends Equatable {
  const MenuNavigationState();

  @override
  List<Object?> get props => [];
}

class MenuNavigationInitial extends MenuNavigationState {}

class MenuItemSelected extends MenuNavigationState {
  final String? previouslySelectedMenuItem;
  final String selectedMenuItem;
  final String? preSelectedDiaryDateString;
  final int unreadNotificationCount;
  final List<String> unreadChatRoomIds;

  const MenuItemSelected({
    required this.selectedMenuItem,
    required this.previouslySelectedMenuItem,
    required this.unreadNotificationCount,
    required this.unreadChatRoomIds,
    this.preSelectedDiaryDateString
  });

  @override
  List<Object?> get props => [
    selectedMenuItem,
    previouslySelectedMenuItem,
    unreadNotificationCount,
    unreadChatRoomIds,
    preSelectedDiaryDateString
  ];
}