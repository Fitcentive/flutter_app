import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

class MenuNavigationBloc extends Bloc<MenuNavigationEvent, MenuNavigationState> {

  MenuNavigationBloc(): super(MenuNavigationInitial()) {
    on<MenuItemChosen>(_menuItemChosen);
  }

  final logger = Logger("MenuNavigationBloc");

  void _menuItemChosen(
      MenuItemChosen event,
      Emitter<MenuNavigationState> emit) async {
    emit(MenuItemSelected(selectedMenuItem: event.selectedMenuItem));
  }
}