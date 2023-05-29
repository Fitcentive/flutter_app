import 'dart:async';

import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/chat_room_updated_stream_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_users.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/chats/room_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/websocket/user_room_updated_payload.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_event.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class ChatHomeBloc extends Bloc<ChatHomeEvent, ChatHomeState> {
  final ChatRepository chatRepository;
  final UserRepository userRepository;
  final PublicGatewayRepository imageRepository;
  final FlutterSecureStorage secureStorage;

  Timer? _heartbeatTimer;
  final roomObserverJoinRef = const Uuid().v4();

  final ChatRoomUpdatedStreamRepository chatRoomUpdatedStreamRepository;
  late final StreamSubscription<UserRoomUpdatedPayload> _userRoomUpdatedPayloadSubscription;

  ChatHomeBloc({
    required this.chatRepository,
    required this.userRepository,
    required this.imageRepository,
    required this.secureStorage,
    required this.chatRoomUpdatedStreamRepository,
  }) : super(const ChatStateInitial()) {
    on<FetchUserRooms>(_fetchUserRooms);
    on<FilterSearchQueryChanged>(_filterSearchQueryChanged);
    on<ChatRoomHasNewMessage>(_chatRoomHasNewMessage);

    _userRoomUpdatedPayloadSubscription = chatRoomUpdatedStreamRepository.nextPayload.listen((payload) {
      add(ChatRoomHasNewMessage(roomId: payload.roomId));
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

      ChatRoomWithMostRecentMessage? newMessage;
      currentState.rooms.forEach((r) {
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
      final List<ChatRoomWithMostRecentMessage> updatedRooms;
      if (newMessage != null) {
        updatedRooms = currentState.rooms.where((element) => element.roomId != event.roomId).toList();
        updatedRooms.insert(0, newMessage!);
      }
      else {
        updatedRooms = currentState.rooms;
      }

      ChatRoomWithMostRecentMessage? newFilteredMessage;
      currentState.filteredRooms.forEach((r) {
        if (r.roomId == event.roomId) {
          newFilteredMessage = ChatRoomWithMostRecentMessage(
              roomId: r.roomId,
              userIds: r.userIds,
              mostRecentMessage: newRoomWithUpdatedMessage.first.mostRecentMessage ?? "",
              mostRecentMessageTime: newRoomWithUpdatedMessage.first.mostRecentMessageTime,
              roomName: r.roomName,
              isGroupChat: r.isGroupChat
          );
        }
      });

      final List<ChatRoomWithMostRecentMessage> updatedFilteredRooms;
      if (newFilteredMessage != null) {
        updatedFilteredRooms = currentState.filteredRooms.where((element) => element.roomId != event.roomId).toList();
        updatedFilteredRooms.insert(0, newFilteredMessage!);
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

    final userRoomsLastSeen = await chatRepository.getUserChatRoomLastSeen(roomIds, accessToken);
    final Map<String, DateTime> roomIdMostRecentMessageTimeMap = { for (var e in userRoomsLastSeen)  (e).roomId : e.lastSeen };

    emit(
        UserRoomsLoaded(
            rooms: chatRoomsWithMostRecentMessage,
            filteredRooms: chatRoomsWithMostRecentMessage,
            userIdProfileMap: userIdProfileMap,
            roomUserLastSeenMap: roomIdMostRecentMessageTimeMap,
        )
    );

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
    _userRoomUpdatedPayloadSubscription.cancel();
  }

}