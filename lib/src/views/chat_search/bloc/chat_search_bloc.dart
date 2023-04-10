import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
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
    on<GetChatRoom>(_getChatRoom);
    on<ChatParticipantsChanged>(_chatParticipantsChanged);
  }

  void _chatParticipantsChanged(ChatParticipantsChanged event, Emitter<ChatSearchState> emit) async {
    final currentState = state;
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    if (currentState is ChatSearchStateInitial) {
      final List<PublicUserProfile> userProfiles;
      if (event.participantUserIds.isNotEmpty) {
        userProfiles = await userRepository.getPublicUserProfiles(event.participantUserIds, accessToken!);
      }
      else {
        userProfiles = [];
      }

      emit(ChatParticipantsModified(
        currentUserProfile: event.currentUserProfile,
        participantUserProfiles: userProfiles,
      ));
    }
    else if (currentState is ChatParticipantsModified) {
      if (event.participantUserIds.isNotEmpty) {
        bool doProfilesAlreadyExistForAll = event
            .participantUserIds
            .map((element) => currentState.participantUserProfiles.map((e) => e.userId).contains(element))
            .reduce((value, element) => value && element);

        if (doProfilesAlreadyExistForAll) {
          emit(ChatParticipantsModified(
            currentUserProfile: event.currentUserProfile,
            participantUserProfiles: currentState.participantUserProfiles,
          ));
        }
        else {
          final additionalUserIdsToGetProfilesFor = event
              .participantUserIds
              .where((meetupParticipantId) => !currentState.participantUserProfiles.map((e) => e.userId).contains(meetupParticipantId))
              .toList();

          final additionalUserProfiles =
            await userRepository.getPublicUserProfiles(additionalUserIdsToGetProfilesFor, accessToken!);

          emit(ChatParticipantsModified(
              currentUserProfile: event.currentUserProfile,
              participantUserProfiles: {...currentState.participantUserProfiles, ...additionalUserProfiles}.toList(),
          ));
        }
      }
      else {
        emit(ChatParticipantsModified(
          currentUserProfile: event.currentUserProfile,
          participantUserProfiles: const [],
        ));
      }


    }
  }

  void _getChatRoom(GetChatRoom event, Emitter<ChatSearchState> emit) async {
    final currentState = state;
    if (currentState is ChatParticipantsModified) {
      try {
        final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

        final chatRoom;
        if (event.targetUserProfiles.isEmpty) {
          // Throw snackbar error over here
        }
        if (event.targetUserProfiles.length == 1) {
          chatRoom = await chatRepository.getChatRoomForPrivateConversation(event.targetUserProfiles.single.userId, accessToken!);
        }
        else {
          chatRoom = await chatRepository.getChatRoomForGroupConversation(event.targetUserProfiles.map((e) => e.userId).toList(), accessToken!);
        }

        emit(GoToUserChatView(roomId: chatRoom.id, targetUserProfiles: event.targetUserProfiles));
        emit(
            ChatParticipantsModified(
                currentUserProfile: currentState.currentUserProfile,
                participantUserProfiles: currentState.participantUserProfiles
            )
        );
      } catch (ex) {
        emit(const TargetUserChatNotEnabled());
        emit(
            ChatParticipantsModified(
                currentUserProfile: currentState.currentUserProfile,
                participantUserProfiles: currentState.participantUserProfiles
            )
        );
      }
    }
  }

}