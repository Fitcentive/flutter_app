import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_event.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedChatBloc extends Bloc<DetailedChatEvent, DetailedChatState> {
  final FlutterSecureStorage secureStorage;
  final ChatRepository chatRepository;

  DetailedChatBloc({
    required this.secureStorage,
    required this.chatRepository,
  }) : super(const DetailedChatStateInitial()) {
    on<ChatRoomNameChanged>(_chatRoomNameChanged);
    on<UsersRemovedFromChatRoom>(_usersRemovedFromChatRoom);
    on<UsersAddedToChatRoom>(_usersAddedToChatRoom);
    on<MakeUserAdminForChatRoom>(_makeUserAdminForChatRoom);
    on<RemoveUserAsAdminFromChatRoom>(_removeUserAsAdminFromChatRoom);
  }

  void _removeUserAsAdminFromChatRoom(RemoveUserAsAdminFromChatRoom event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await chatRepository.removeChatRoomAdmins(event.roomId, event.userId, accessToken!);
  }

  void _makeUserAdminForChatRoom(MakeUserAdminForChatRoom event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await chatRepository.upsertChatRoomAdmins(event.roomId, event.userId, accessToken!);
  }

  void _usersAddedToChatRoom(UsersAddedToChatRoom event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await Future.forEach<String>(
        event.userIds,
            (userId) => chatRepository.addUserToChatRoom(event.roomId, userId, accessToken!)
    );
  }

  void _usersRemovedFromChatRoom(UsersRemovedFromChatRoom event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await Future.forEach<String>(
        event.userIds,
            (userId) => chatRepository.removeUserFromChatRoom(event.roomId, userId, accessToken!)
    );
  }

  void _chatRoomNameChanged(ChatRoomNameChanged event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await chatRepository.updateChatRoomName(event.roomIds, event.newName, accessToken!);
  }

}