import 'dart:async';

import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/chat_room_updated_stream_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/chats/detailed_chat_room.dart';
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
    on<FetchMoreUserRooms>(_fetchMoreUserRooms);
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
                  element.roomName.toLowerCase().contains(event.query.toLowerCase()) ||
                      _doesQueryMatchUserIds(event.query, element.userIds, currentState.userIdProfileMap)
            )
            .toList();
        emit(
            UserRoomsLoaded(
              rooms: currentState.rooms,
              filteredRooms: filteredRooms,
              userIdProfileMap: currentState.userIdProfileMap,
              roomUserLastSeenMap: currentState.roomUserLastSeenMap,
              doesNextPageExist: currentState.doesNextPageExist,
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
              doesNextPageExist: currentState.doesNextPageExist,
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
            doesNextPageExist: currentState.doesNextPageExist,
          )
      );
    }
  }

  void _fetchMoreUserRooms(FetchMoreUserRooms event, Emitter<ChatHomeState> emit) async {
    final currentState = state;

    if (currentState is UserRoomsLoaded && currentState.doesNextPageExist) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final detailedChatRooms = await chatRepository.getDetailedChatRoomsForUser(
          event.userId,
          event.limit,
          currentState.rooms.length,
          accessToken!
      );

      final currentStateRoomIds = currentState.rooms.map((e) => e.roomId).toList();
      final chatRoomsWithMostRecentMessage = detailedChatRooms
          .where((element) => !currentStateRoomIds.contains(element.roomId))
          .map((e) =>
            ChatRoomWithMostRecentMessage(
                roomId: e.roomId,
                userIds: e.userIds,
                mostRecentMessage: e.mostRecentMessage ?? "",
                mostRecentMessageTime: e.mostRecentMessageTimestamp ?? DateTime.now().subtract(const Duration(hours: 1)),
                roomName: e.roomName,
                isGroupChat: e.roomType == "group"
            )
          ).toList();

      final distinctUserIdsFromPosts = _getDistinctUserIdsFromChatRooms(detailedChatRooms);
      final additionalIdsToFetchDataFor = distinctUserIdsFromPosts
          .where((element) => !currentState.userIdProfileMap.keys.contains(element))
          .toList();
      final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(additionalIdsToFetchDataFor, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      final userRoomsLastSeen = await chatRepository.getUserChatRoomLastSeen(
          detailedChatRooms.map((e) => e.roomId).toList(),
          accessToken
      );
      final Map<String, DateTime> roomIdMostRecentMessageTimeMap = { for (var e in userRoomsLastSeen)  (e).roomId : e.lastSeen };

      final doesNextPageExist = detailedChatRooms.length == event.limit ? true : false;

      emit(
          UserRoomsLoaded(
            rooms: [...currentState.rooms, ...chatRoomsWithMostRecentMessage],
            filteredRooms: [...currentState.filteredRooms, ...chatRoomsWithMostRecentMessage],
            userIdProfileMap: {...currentState.userIdProfileMap, ...userIdProfileMap},
            roomUserLastSeenMap: {...currentState.roomUserLastSeenMap, ...roomIdMostRecentMessageTimeMap},
            doesNextPageExist: doesNextPageExist,
          )
      );
    }
  }

  void _fetchUserRooms(FetchUserRooms event, Emitter<ChatHomeState> emit) async {
    emit(const UserRoomsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final detailedChatRooms = await chatRepository.getDetailedChatRoomsForUser(
        event.userId,
        event.limit,
        event.offset,
        accessToken!
    );

    // final chatRoomDefinitions = await chatRepository.getChatRoomDefinitions(chatRooms.map((e) => e.roomId).toList(), accessToken);
    // final roomIds = chatRooms.map((e) => e.roomId).toList();
    // final roomMostRecentMessages = await chatRepository.getRoomMostRecentMessage(roomIds, accessToken);
    // final Map<String, RoomMostRecentMessage> roomIdMostRecentMessageMap = { for (var e in roomMostRecentMessages) (e).roomId : e };
    final chatRoomsWithMostRecentMessage = detailedChatRooms.map((e) =>
        ChatRoomWithMostRecentMessage(
            roomId: e.roomId,
            userIds: e.userIds,
            mostRecentMessage: e.mostRecentMessage ?? "",
            mostRecentMessageTime: e.mostRecentMessageTimestamp ?? DateTime.now().subtract(const Duration(hours: 1)),
            roomName: e.roomName,
            isGroupChat: e.roomType == "group"
        )
    ).toList();

    final distinctUserIdsFromPosts = _getDistinctUserIdsFromChatRooms(detailedChatRooms);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    final userRoomsLastSeen = await chatRepository.getUserChatRoomLastSeen(
        detailedChatRooms.map((e) => e.roomId).toList(),
        accessToken
    );
    final Map<String, DateTime> roomIdMostRecentMessageTimeMap = { for (var e in userRoomsLastSeen)  (e).roomId : e.lastSeen };

    final doesNextPageExist = detailedChatRooms.length == event.limit ? true : false;

    emit(
        UserRoomsLoaded(
          rooms: chatRoomsWithMostRecentMessage,
          filteredRooms: chatRoomsWithMostRecentMessage,
          userIdProfileMap: userIdProfileMap,
          roomUserLastSeenMap: roomIdMostRecentMessageTimeMap,
          doesNextPageExist: doesNextPageExist,
        )
    );

  }

  List<String> _getDistinctUserIdsFromChatRooms(List<DetailedChatRoom> rooms) {
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