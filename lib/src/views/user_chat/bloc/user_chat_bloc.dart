import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_event.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserChatBloc extends Bloc<UserChatEvent, UserChatState> {
  final ChatRepository chatRepository;
  final FlutterSecureStorage secureStorage;

  UserChatBloc({
    required this.chatRepository,
    required this.secureStorage,
  }) : super(const UserChatStateInitial()) {
    on<FetchHistoricalChats>(_fetchHistoricalChats);
  }

  void _fetchHistoricalChats(FetchHistoricalChats event, Emitter<UserChatState> emit) async {
    emit(const HistoricalChatsLoading());

    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final chatMessages = await chatRepository.getMessagesForRoom(event.roomId, accessToken!);
    emit(HistoricalChatsFetched(roomId: event.roomId, messages: chatMessages));
  }
}