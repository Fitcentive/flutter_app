import 'dart:async';
import 'dart:convert';

import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/image_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_users.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/chats/room_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/websocket/room_updated_payload.dart';
import 'package:flutter_app/src/models/websocket/web_socket_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_event.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatHomeBloc extends Bloc<ChatHomeEvent, ChatHomeState> {
  final ChatRepository chatRepository;
  final UserRepository userRepository;
  final ImageRepository imageRepository;
  final FlutterSecureStorage secureStorage;

  Map<String, WebSocketChannel>? _roomObserverChannels;
  Timer? _heartbeatTimer;
  final roomObserverJoinRef = const Uuid().v4();

  bool hasSocketBeenInitialized = false;

  ChatHomeBloc({
    required this.chatRepository,
    required this.userRepository,
    required this.imageRepository,
    required this.secureStorage,
  }) : super(const ChatStateInitial()) {
    on<FetchUserRooms>(_fetchUserRooms);
    on<FilterSearchQueryChanged>(_filterSearchQueryChanged);
    on<ChatRoomHasNewMessage>(_chatRoomHasNewMessage);
  }

  _setUpRoomObserverChannelsHeartbeats(String currentUserId) {
    _heartbeatTimer = Timer(const Duration(seconds: 30), () {
      _roomObserverChannels?.entries.forEach((entry) {
        entry.value.sink.add(jsonEncode({
          "topic": "room_observer:${entry.key}",
          "event": "ping",
          "payload": {
            "user_id": currentUserId
          },
          "join_ref": roomObserverJoinRef,
          "ref": const Uuid().v4()
        }));
      });

      _setUpRoomObserverChannelsHeartbeats(currentUserId);
    });
  }

  _initializeWebsocketConnections(List<String> roomIds, String currentUserId) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    _roomObserverChannels = Map.fromEntries(roomIds.map((e) {
      return MapEntry(e, WebSocketChannel.connect(
        Uri.parse('wss://${ConstantUtils.API_HOSTNAME}/api/chat/socket/websocket?token=${accessToken}'),
      ));
    }));

    _roomObserverChannels?.entries.forEach((entry) {
      entry.value.sink.add(jsonEncode({
        "topic": "room_observer:${entry.key}",
        "event": "phx_join",
        "payload": {
          "user_id": currentUserId
        },
        "join_ref": roomObserverJoinRef,
        "ref": const Uuid().v4()
      }));
    });

    _setUpRoomObserverChannelsHeartbeats(currentUserId);

    _roomObserverChannels?.entries.forEach((entry) {
      entry.value.stream.listen((event) {
        final decodedJson = jsonDecode(event);
        final websocketEvent = WebsocketEvent.fromJson(decodedJson);

        switch (websocketEvent.event) {
          case "room_updated":
            final Map<String, dynamic> decodedRoomUpdatedJson = jsonDecode(jsonEncode(websocketEvent.payload));
            final roomUpdatedPayload = RoomUpdatedPayload.fromJson(decodedRoomUpdatedJson);
            add(ChatRoomHasNewMessage(roomId: roomUpdatedPayload.roomId));
            break;

          default:
            break;
        }
      });
    });
  }

  // Returns true if query matches names of any of the users listed in userIds
  bool _doesQueryMatchUserIds(String query, List<String> userIds, Map<String, PublicUserProfile> userIdProfileMap) {
    return userIds
        .map((e) => userIdProfileMap[e]!)
        .where((element) =>
                element.firstName!.toLowerCase().contains(query.toLowerCase()) ||
                element.lastName!.toLowerCase().contains(query.toLowerCase()))
        .isNotEmpty;
  }

  void _filterSearchQueryChanged(FilterSearchQueryChanged event, Emitter<ChatHomeState> emit) async {
    final currentState = state;
    if (currentState is UserRoomsLoaded) {
      if (event.query.isNotEmpty) {
        final filteredRooms = currentState.rooms
            .where((element) =>
        element.roomName.contains(event.query) || _doesQueryMatchUserIds(event.query, element.userIds, currentState.userIdProfileMap)
        )
            .toList();
        emit(
            UserRoomsLoaded(
              rooms: currentState.rooms,
              filteredRooms: filteredRooms,
              userIdProfileMap: currentState.userIdProfileMap,
              roomUserLastSeenMap: currentState.roomUserLastSeenMap,
            )
        );
      }
      else {
        emit(
            UserRoomsLoaded(
              rooms: currentState.rooms,
              filteredRooms: currentState.rooms,
              userIdProfileMap: currentState.userIdProfileMap,
              roomUserLastSeenMap: currentState.roomUserLastSeenMap,
            )
        );
      }
    }
  }

  void _chatRoomHasNewMessage(ChatRoomHasNewMessage event, Emitter<ChatHomeState> emit) async {
    final currentState = state;
    if (currentState is UserRoomsLoaded) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final newRoomWithUpdatedMessage = await chatRepository.getRoomMostRecentMessage([event.roomId], accessToken!);

      final updatedRooms = currentState.rooms.map((r) {
        if (r.roomId != event.roomId) {
          return r;
        }
        else {
          return ChatRoomWithMostRecentMessage(
              roomId: r.roomId,
              userIds: r.userIds,
              mostRecentMessage: newRoomWithUpdatedMessage.first.mostRecentMessage ?? "",
              mostRecentMessageTime: newRoomWithUpdatedMessage.first.mostRecentMessageTime,
              roomName: r.roomName,
              isGroupChat: r.isGroupChat
          );
        }
      }).toList();

      ChatRoomWithMostRecentMessage? newMessage;
      currentState.filteredRooms.forEach((r) {
        if (r.roomId == event.roomId) {
          newMessage = ChatRoomWithMostRecentMessage(
              roomId: r.roomId,
              userIds: r.userIds,
              mostRecentMessage: newRoomWithUpdatedMessage.first.mostRecentMessage ?? "",
              mostRecentMessageTime: newRoomWithUpdatedMessage.first.mostRecentMessageTime,
              roomName: r.roomName,
              isGroupChat: r.isGroupChat
          );
        }
      });

      final updatedFilteredRooms;
      if (newMessage != null) {
        updatedFilteredRooms = currentState.filteredRooms.where((element) => element.roomId != event.roomId).toList();
        updatedFilteredRooms.insert(0, newMessage!);
      }
      else {
        updatedFilteredRooms = currentState.filteredRooms;
      }


      emit(
          UserRoomsLoaded(
            rooms: updatedRooms,
            filteredRooms: updatedFilteredRooms,
            userIdProfileMap: currentState.userIdProfileMap,
            roomUserLastSeenMap: currentState.roomUserLastSeenMap,
          )
      );
    }
  }


  
  void _fetchUserRooms(FetchUserRooms event, Emitter<ChatHomeState> emit) async {
    emit(const UserRoomsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final chatRooms = await chatRepository.getUserChatRooms(event.userId, accessToken!);
    final chatRoomDefinitions = await chatRepository.getChatRoomDefinitions(chatRooms.map((e) => e.roomId).toList(), accessToken);

    final roomIds = chatRooms.map((e) => e.roomId).toList();
    final roomMostRecentMessages = await chatRepository.getRoomMostRecentMessage(roomIds, accessToken);
    final Map<String, RoomMostRecentMessage> roomIdMostRecentMessageMap = { for (var e in roomMostRecentMessages) (e).roomId : e };
    final chatRoomsWithMostRecentMessage = chatRooms.map((e) =>
        ChatRoomWithMostRecentMessage(
            roomId: e.roomId,
            userIds: e.userIds,
            mostRecentMessage: roomIdMostRecentMessageMap[e.roomId]?.mostRecentMessage ?? "",
            mostRecentMessageTime: roomIdMostRecentMessageMap[e.roomId]?.mostRecentMessageTime ?? DateTime.now(),
            roomName: chatRoomDefinitions.firstWhere((element) => element.id == e.roomId).name,
            isGroupChat: chatRoomDefinitions.firstWhere((element) => element.id == e.roomId).type == "group"
        )
    ).toList();

    final distinctUserIdsFromPosts = _getDistinctUserIdsFromChatRooms(chatRooms);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    final userRoomsLastSeen = await Future.wait(roomIds.map((e) => chatRepository.getUserChatRoomLastSeen(e, accessToken)));
    final Map<String, DateTime> roomIdMostRecentMessageTimeMap =
      { for (var e in WidgetUtils.skipNulls(userRoomsLastSeen))  (e).roomId : e.lastSeen };

    emit(
        UserRoomsLoaded(
            rooms: chatRoomsWithMostRecentMessage,
            filteredRooms: chatRoomsWithMostRecentMessage,
            userIdProfileMap: userIdProfileMap,
            roomUserLastSeenMap: roomIdMostRecentMessageTimeMap,
        )
    );

    if (!hasSocketBeenInitialized) {
      _initializeWebsocketConnections(chatRoomsWithMostRecentMessage.map((e) => e.roomId).toList(), event.userId);
      hasSocketBeenInitialized = true;
    }
  }

  List<String> _getDistinctUserIdsFromChatRooms(List<ChatRoomWithUsers> rooms) {
    final userIdSet = rooms
        .map((e) => e.userIds)
        .expand((element) => element)
        .toSet();
    userIdSet.add(ConstantUtils.staticDeletedUserId);
    return userIdSet.toList();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _roomObserverChannels?.entries.forEach((element) {
      element.value.sink.close();
    });
  }

}