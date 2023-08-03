import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_event.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoveredUserBloc extends Bloc<DiscoveredUserEvent, DiscoveredUserState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;
  final SocialMediaRepository socialMediaRepository;
  final ChatRepository chatRepository;
  final UserRepository userRepository;

  DiscoveredUserBloc({
    required this.discoverRepository,
    required this.socialMediaRepository,
    required this.userRepository,
    required this.chatRepository,
    required this.secureStorage,
  }) : super(const DiscoveredUserStateInitial()) {
    on<FetchDiscoveredUserPreferences>(_fetchDiscoveredUserPreferences);
    on<GetChatRoom>(_getChatRoom);
  }

  void _getChatRoom(GetChatRoom event, Emitter<DiscoveredUserState> emit) async {
    final currenState = state;
    try {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final chatRoom = await chatRepository.getChatRoomForPrivateConversation(event.otherUserProfile.userId, accessToken!);

      emit(GoToUserChatView(roomId: chatRoom.id, otherUserProfile: event.otherUserProfile));
      emit(currenState);
    } catch (ex) {
      emit(const TargetUserChatNotEnabled());
      emit(currenState);
    }
  }


  void _fetchDiscoveredUserPreferences(FetchDiscoveredUserPreferences event, Emitter<DiscoveredUserState> emit) async {
    emit(const DiscoveredUserDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final allUserPrefs = await discoverRepository.getAllUserPreferences(event.otherUserId, accessToken!);
    // final userDiscoverPreferences = await discoverRepository.getUserDiscoveryPreferences(event.otherUserId, accessToken!);
    // final userPersonalPreferences = await discoverRepository.getUserPersonalPreferences(event.otherUserId, accessToken);
    // final userFitnessPreferences = await discoverRepository.getUserFitnessPreferences(event.otherUserId, accessToken);
    // final userGymPreferences = await discoverRepository.getUserGymPreferences(event.otherUserId, accessToken);
    final otherUserProfile = (await userRepository.getPublicUserProfiles([event.otherUserId], accessToken)).first;
    final discoverScore = await discoverRepository.getUserDiscoverScore(event.currentUserId, event.otherUserId, accessToken);
    final userFriendStatus =
      await socialMediaRepository.getUserFriendStatus(event.currentUserId, event.otherUserId, accessToken!);
    emit(DiscoveredUserPreferencesFetched(
        discoveryPreferences: allUserPrefs.userDiscoveryPreferences,
        personalPreferences: allUserPrefs.userPersonalPreferences,
        fitnessPreferences: allUserPrefs.userFitnessPreferences,
        otherUserProfile: otherUserProfile,
        discoverScore: discoverScore,
        gymPreferences: allUserPrefs.userGymPreferences,
        userFriendStatus: userFriendStatus,
    ));
  }
}