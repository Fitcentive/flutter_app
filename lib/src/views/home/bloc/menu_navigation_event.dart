import 'package:equatable/equatable.dart';

abstract class MenuNavigationEvent extends Equatable {
  const MenuNavigationEvent();
}

class MenuItemChosen extends MenuNavigationEvent {
  final String selectedMenuItem;

  const MenuItemChosen({
    required this.selectedMenuItem
  });

  @override
  List<Object> get props => [selectedMenuItem];

  @override
  String toString() => 'MenuItemChosen {  $selectedMenuItem }';
}