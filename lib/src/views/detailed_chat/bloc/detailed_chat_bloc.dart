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
    on<UserRemovedFromChatRoom>(_userRemovedFromChatRoom);
    on<UserAddedToChatRoom>(_userAddedToChatRoom);
  }

  void _userAddedToChatRoom(UserAddedToChatRoom event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await chatRepository.addUserToChatRoom(event.roomId, event.userId, accessToken!);
  }

  void _userRemovedFromChatRoom(UserRemovedFromChatRoom event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await chatRepository.removeUserFromChatRoom(event.roomId, event.userId, accessToken!);
  }

  void _chatRoomNameChanged(ChatRoomNameChanged event, Emitter<DetailedChatState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await chatRepository.updateChatRoomName(event.roomId, event.newName, accessToken!);
  }

}