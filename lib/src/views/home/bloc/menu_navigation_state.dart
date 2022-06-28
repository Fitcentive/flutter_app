import 'package:equatable/equatable.dart';

abstract class MenuNavigationState extends Equatable {
  const MenuNavigationState();

  @override
  List<Object> get props => [];
}

class MenuNavigationInitial extends MenuNavigationState {}

class MenuItemSelected extends MenuNavigationState {
  final String selectedMenuItem;

  const MenuItemSelected({
    required this.selectedMenuItem
  });

  @override
  List<Object> get props => [selectedMenuItem];
}