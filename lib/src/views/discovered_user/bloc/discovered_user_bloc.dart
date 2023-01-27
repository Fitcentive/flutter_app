import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_event.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoveredUserBloc extends Bloc<DiscoveredUserEvent, DiscoveredUserState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;
  final UserRepository userRepository;

  DiscoveredUserBloc({
    required this.discoverRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const DiscoveredUserStateInitial()) {
    on<FetchDiscoveredUserPreferences>(_fetchDiscoveredUserPreferences);
  }

  void _fetchDiscoveredUserPreferences(FetchDiscoveredUserPreferences event, Emitter<DiscoveredUserState> emit) async {
    emit(const DiscoveredUserDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userDiscoverPreferences = await discoverRepository.getUserDiscoveryPreferences(event.otherUserId, accessToken!);
    final userPersonalPreferences = await discoverRepository.getUserPersonalPreferences(event.otherUserId, accessToken);
    final userFitnessPreferences = await discoverRepository.getUserFitnessPreferences(event.otherUserId, accessToken);
    final userGymPreferences = await discoverRepository.getUserGymPreferences(event.otherUserId, accessToken);
    final otherUserProfile = (await userRepository.getPublicUserProfiles([event.otherUserId], accessToken)).first;
    final discoverScore = await discoverRepository.getUserDiscoverScore(event.currentUserId, event.otherUserId, accessToken);
    emit(DiscoveredUserPreferencesFetched(
        discoveryPreferences: userDiscoverPreferences,
        personalPreferences: userPersonalPreferences,
        fitnessPreferences: userFitnessPreferences,
        otherUserProfile: otherUserProfile,
        discoverScore: discoverScore,
        gymPreferences: userGymPreferences
    ));
  }
}