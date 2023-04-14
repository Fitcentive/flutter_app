import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/image_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_users.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_event.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatHomeBloc extends Bloc<ChatHomeEvent, ChatHomeState> {
  final ChatRepository chatRepository;
  final UserRepository userRepository;
  final ImageRepository imageRepository;
  final FlutterSecureStorage secureStorage;

  ChatHomeBloc({
    required this.chatRepository,
    required this.userRepository,
    required this.imageRepository,
    required this.secureStorage,
  }) : super(const ChatStateInitial()) {
    on<FetchUserRooms>(_fetchUserRooms);
    on<FilterSearchQueryChanged>(_filterSearchQueryChanged);
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
            )
        );
      }
      else {
        emit(
            UserRoomsLoaded(
              rooms: currentState.rooms,
              filteredRooms: currentState.rooms,
              userIdProfileMap: currentState.userIdProfileMap,
            )
        );
      }
    }
  }
  
  void _fetchUserRooms(FetchUserRooms event, Emitter<ChatHomeState> emit) async {
    emit(const UserRoomsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final chatRooms = await chatRepository.getUserChatRooms(event.userId, accessToken!);
    final chatRoomDefinitions = await chatRepository.getChatRoomDefinitions(chatRooms.map((e) => e.roomId).toList(), accessToken);

    final roomIds = chatRooms.map((e) => e.roomId).toList();
    final roomMostRecentMessages = await chatRepository.getRoomMostRecentMessage(roomIds, accessToken);
    final Map<String, String> roomIdMostRecentMessageMap =
    { for (var e in roomMostRecentMessages) (e).roomId : e.mostRecentMessage };
    final chatRoomsWithMostRecentMessage = chatRooms.map((e) =>
        ChatRoomWithMostRecentMessage(
            roomId: e.roomId,
            userIds: e.userIds,
            mostRecentMessage: roomIdMostRecentMessageMap[e.roomId] ?? "",
            roomName: chatRoomDefinitions.firstWhere((element) => element.id == e.roomId).name,
            isGroupChat: chatRoomDefinitions.firstWhere((element) => element.id == e.roomId).type == "group"
        )
    ).toList();

    final distinctUserIdsFromPosts = _getDistinctUserIdsFromChatRooms(chatRooms);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(
        UserRoomsLoaded(
            rooms: chatRoomsWithMostRecentMessage,
            filteredRooms: chatRoomsWithMostRecentMessage,
            userIdProfileMap: userIdProfileMap,
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

}