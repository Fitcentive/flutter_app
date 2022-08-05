import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_event.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatSearchBloc extends Bloc<ChatSearchEvent, ChatSearchState> {

  final ChatRepository chatRepository;
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  ChatSearchBloc({
    required this.chatRepository,
    required this.userRepository,
    required this.secureStorage
  }): super(const ChatSearchStateInitial()) {
    on<ChatSearchQueryChanged>(_searchQueryChanged);
    on<GetChatRoom>(_getChatRoom);
  }

  void _getChatRoom(GetChatRoom event, Emitter<ChatSearchState> emit) async {
    final currentState = state;
    if (currentState is ChatSearchResultsLoaded) {
      try {
        final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
        final chatRoom = await chatRepository.getChatRoomForConversation(event.targetUserProfile.userId, accessToken!);

        emit(GoToUserChatView(roomId: chatRoom.id, targetUserProfile: event.targetUserProfile));
        emit(ChatSearchResultsLoaded(query: currentState.query, userData: currentState.userData));
      } catch (ex) {
        emit(const TargetUserChatNotEnabled());
        emit(ChatSearchResultsLoaded(query: currentState.query, userData: currentState.userData));
      }
    }
  }

  void _searchQueryChanged(ChatSearchQueryChanged event, Emitter<ChatSearchState> emit) async {
    if (event.query.isNotEmpty) {
      emit(ChatSearchResultsLoading(query: event.query));
      try {
        final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
        final results = await userRepository.searchForUsers(event.query, 100, accessToken!);
        emit(ChatSearchResultsLoaded(query: event.query, userData: results));
      } catch (ex) {
        emit(ChatSearchResultsError(query: event.query, error: ex.toString()));
      }
    }
    else {
      final currentState = state;
      if (currentState is ChatSearchResultsLoaded) {
        emit(ChatSearchResultsLoaded(query: "", userData: currentState.userData));
      }
    }
  }

}