import 'dart:async';
import 'dart:convert';

import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/websocket/room_updated_payload.dart';
import 'package:flutter_app/src/models/websocket/web_socket_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MenuNavigationBloc extends Bloc<MenuNavigationEvent, MenuNavigationState> {
  final NotificationRepository notificationRepository;
  final FlutterSecureStorage secureStorage;

  Timer? _heartbeatTimer;
  bool hasSocketBeenInitialized = false;
  final joinRef = const Uuid().v4();

  WebSocketChannel? _userChatRoomUpdatesChannel;

  MenuNavigationBloc({
    required this.notificationRepository,
    required this.secureStorage,
  }): super(MenuNavigationInitial()) {
    on<MenuItemChosen>(_menuItemChosen);
    on<NewIncomingChatMessageForRoom>(_newIncomingChatMessageForRoom);
    on<ReInitWebSockets>(_reInitWebSockets);
  }

  final logger = Logger("MenuNavigationBloc");

  void _reInitWebSockets(ReInitWebSockets event, Emitter<MenuNavigationState> emit) async {
    dispose();
    _initializeWebsocketConnections(event.currentUserId);
  }

  _setUpHeartbeats(String currentUserId) {
    _heartbeatTimer = Timer(const Duration(seconds: 30), () {
      _userChatRoomUpdatesChannel?.sink.add(jsonEncode({
        "topic": "user_room_observer:$currentUserId",
        "event": "ping",
        "payload": {
          "user_id": currentUserId
        },
        "join_ref": joinRef,
        "ref": const Uuid().v4()
      }));

      _setUpHeartbeats(currentUserId);
    });
  }

  _initializeWebsocketConnections(String currentUserId) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // wss works because we allow for unverified certificates in development mode
    _userChatRoomUpdatesChannel = WebSocketChannel.connect(
      Uri.parse('wss://${ConstantUtils.API_HOSTNAME}/api/chat/socket/websocket?token=${accessToken!}'),
    );

    _userChatRoomUpdatesChannel?.sink.add(jsonEncode({
      "topic": "user_room_observer:$currentUserId",
      "event": "phx_join",
      "payload": {
        "user_id": currentUserId
      },
      "join_ref": joinRef,
      "ref": const Uuid().v4()
    }));

    _setUpHeartbeats(currentUserId);

    _userChatRoomUpdatesChannel?.stream.listen((event) {
      final decodedJson = jsonDecode(event);
      final websocketEvent = WebsocketEvent.fromJson(decodedJson);

      switch (websocketEvent.event) {
        case "user_room_updated":
          final Map<String, dynamic> decodedShoutJson = jsonDecode(jsonEncode(websocketEvent.payload));
          final roomPayload = RoomUpdatedPayload.fromJson(decodedShoutJson); // Same payload type so we reuse the structure RoomUpdatedPayload
            add(NewIncomingChatMessageForRoom(roomId: roomPayload.roomId));
          break;

        default:
          break;
      }
    });
  }

  void _newIncomingChatMessageForRoom(NewIncomingChatMessageForRoom event, Emitter<MenuNavigationState> emit) async {
    final currentState = state;
    if (currentState is MenuItemSelected) {
      if (!currentState.unreadChatRoomIds.contains(event.roomId)) {
        emit(MenuItemSelected(
            selectedMenuItem: currentState.selectedMenuItem,
            unreadNotificationCount: currentState.unreadNotificationCount,
            unreadChatRoomIds: [...currentState.unreadChatRoomIds, event.roomId]
        ));
      } // If room updated is already contained, then we do nothing
    }
  }

  void _menuItemChosen(MenuItemChosen event, Emitter<MenuNavigationState> emit) async {
    if (!hasSocketBeenInitialized) {
      _initializeWebsocketConnections(event.currentUserId);
      hasSocketBeenInitialized = true;
    }

    final currentState = state;

    emit(MenuItemSelected(
      selectedMenuItem: event.selectedMenuItem,
      unreadNotificationCount: 0,
      unreadChatRoomIds: const [],
    ));

    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final unreadNotificationCount = await notificationRepository.getUnreadNotificationCount(event.currentUserId, accessToken!);

    if (currentState is MenuItemSelected) {
      // Check if we are navigating INTO chat, or AWAY from chat (having already been there)
      if (event.selectedMenuItem == HomePageState.chat || currentState.selectedMenuItem == HomePageState.chat ) {
        emit(MenuItemSelected(
            selectedMenuItem: event.selectedMenuItem,
            unreadNotificationCount: unreadNotificationCount,
            unreadChatRoomIds: const [],
        ));
      }
      else {
        emit(MenuItemSelected(
            selectedMenuItem: event.selectedMenuItem,
            unreadNotificationCount: unreadNotificationCount,
            unreadChatRoomIds: currentState.unreadChatRoomIds
        ));
      }
    }
    else {
      emit(MenuItemSelected(
          selectedMenuItem: event.selectedMenuItem,
          unreadNotificationCount: unreadNotificationCount,
          unreadChatRoomIds: const []
      ));
    }

  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _userChatRoomUpdatesChannel?.sink.close();
  }
}