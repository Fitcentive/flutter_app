import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_event.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverHomeBloc extends Bloc<DiscoverHomeEvent, DiscoverHomeState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;

  DiscoverHomeBloc({
    required this.discoverRepository,
    required this.secureStorage,
  }) : super(const DiscoverHomeStateInitial()) {
    on<FetchUserDiscoverData>(_fetchUserDiscoverPreferences);
    on<RemoveUserFromListOfDiscoveredUsers>(_removeUserFromListOfDiscoveredUsers);
  }

  void _removeUserFromListOfDiscoveredUsers(RemoveUserFromListOfDiscoveredUsers event, Emitter<DiscoverHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await discoverRepository.removeDiscoveredUser(event.currentUserId, event.discoveredUserId, accessToken!);
  }

  void _fetchUserDiscoverPreferences(FetchUserDiscoverData event, Emitter<DiscoverHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userDiscoverPreferences = await discoverRepository.getUserDiscoveryPreferences(event.userId, accessToken!);
    final userPersonalPreferences = await discoverRepository.getUserPersonalPreferences(event.userId, accessToken);
    final userFitnessPreferences = await discoverRepository.getUserFitnessPreferences(event.userId, accessToken);
    final userProfiles = await discoverRepository.getDiscoveredUserProfiles(event.userId, accessToken);

    emit(DiscoverUserDataFetched(
      discoveryPreferences: userDiscoverPreferences,
      personalPreferences: userPersonalPreferences,
      fitnessPreferences: userFitnessPreferences,
      discoveredUserProfiles: userProfiles
    ));
  }
}