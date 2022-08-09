import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class MenuNavigationBloc extends Bloc<MenuNavigationEvent, MenuNavigationState> {
  final NotificationRepository notificationRepository;
  final FlutterSecureStorage secureStorage;

  MenuNavigationBloc({
    required this.notificationRepository,
    required this.secureStorage,
  }): super(MenuNavigationInitial()) {
    on<MenuItemChosen>(_menuItemChosen);
  }

  final logger = Logger("MenuNavigationBloc");

  void _menuItemChosen(MenuItemChosen event, Emitter<MenuNavigationState> emit) async {
    emit(MenuItemSelected(
      selectedMenuItem: event.selectedMenuItem,
      unreadNotificationCount: 0,
    ));

    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final unreadNotificationCount = await notificationRepository.getUnreadNotificationCount(event.currentUserId, accessToken!);
    emit(MenuItemSelected(
      selectedMenuItem: event.selectedMenuItem,
      unreadNotificationCount: unreadNotificationCount,
    ));
  }
}