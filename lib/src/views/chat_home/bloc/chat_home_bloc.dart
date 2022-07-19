import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_users.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/repos/rest/image_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
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
  }

  void _fetchUserRooms(FetchUserRooms event, Emitter<ChatHomeState> emit) async {
    emit(const UserRoomsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final chatRooms = await chatRepository.getUserChatRooms(event.userId, accessToken!);

    final roomIds = chatRooms.map((e) => e.roomId).toList();
    final roomMostRecentMessages = await chatRepository.getRoomMostRecentMessage(roomIds, accessToken);
    final Map<String, String> roomIdMostRecentMessageMap =
    { for (var e in roomMostRecentMessages) (e).roomId : e.mostRecentMessage };
    final chatRoomsWithMostRecentMessage = chatRooms.map((e) =>
        ChatRoomWithMostRecentMessage(
            roomId: e.roomId,
            userIds: e.userIds,
            mostRecentMessage: roomIdMostRecentMessageMap[e.roomId] ?? ""
        )
    ).toList();

    final distinctUserIdsFromPosts = _getDistinctUserIdsFromChatRooms(chatRooms);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(UserRoomsLoaded(rooms: chatRoomsWithMostRecentMessage, userIdProfileMap: userIdProfileMap));
  }

  List<String> _getDistinctUserIdsFromChatRooms(List<ChatRoomWithUsers> rooms) {
    return rooms
        .map((e) => e.userIds)
        .expand((element) => element)
        .toSet()
        .toList();
  }

}