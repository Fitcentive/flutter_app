import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_event.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverHomeBloc extends Bloc<DiscoverHomeEvent, DiscoverHomeState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;
  final UserRepository userRepository;

  DiscoverHomeBloc({
    required this.discoverRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const DiscoverHomeStateInitial()) {
    on<FetchUserDiscoverData>(_fetchUserDiscoverPreferences);
    on<FetchMoreDiscoveredUsers>(_fetchMoreDiscoveredUsers);
    on<RemoveUserFromListOfDiscoveredUsers>(_removeUserFromListOfDiscoveredUsers);
    on<AddUserToListOfDiscoveredUsers>(_addUserToListOfDiscoveredUsers);
  }

  void _addUserToListOfDiscoveredUsers(AddUserToListOfDiscoveredUsers event, Emitter<DiscoverHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await discoverRepository.upsertDiscoveredUser(event.currentUserId, event.discoveredUserId, accessToken!);
  }

  void _removeUserFromListOfDiscoveredUsers(RemoveUserFromListOfDiscoveredUsers event, Emitter<DiscoverHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await discoverRepository.removeDiscoveredUser(event.currentUserId, event.discoveredUserId, accessToken!);
    userRepository.trackUserEvent(RemoveFromNewlyDiscoveredUsers(), accessToken);
  }

  void _fetchMoreDiscoveredUsers(FetchMoreDiscoveredUsers event, Emitter<DiscoverHomeState> emit) async {
    final currentState = state;
    if (currentState is DiscoverUserDataFetched && currentState.doesNextPageExist) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final userProfiles = await discoverRepository.getDiscoveredUserProfiles(
          event.userId,
          accessToken!,
          ConstantUtils.DEFAULT_LIMIT,
          currentState.discoveredUserProfiles.length
      );
      final doesNextPageExist = userProfiles.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      final newUserProfiles = [...currentState.discoveredUserProfiles, ...userProfiles];

      emit(DiscoverUserDataFetched(
        discoveryPreferences: currentState.discoveryPreferences,
        personalPreferences: currentState.personalPreferences,
        fitnessPreferences: currentState.fitnessPreferences,
        discoveredUserProfiles: newUserProfiles,
        doesNextPageExist: doesNextPageExist,
      ));
    }
  }

  void _fetchUserDiscoverPreferences(FetchUserDiscoverData event, Emitter<DiscoverHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final allUserPrefs = await discoverRepository.getAllUserPreferences(event.userId, accessToken!);
    // final userDiscoverPreferences = await discoverRepository.getUserDiscoveryPreferences(event.userId, accessToken!);
    // final userPersonalPreferences = await discoverRepository.getUserPersonalPreferences(event.userId, accessToken);
    // final userFitnessPreferences = await discoverRepository.getUserFitnessPreferences(event.userId, accessToken);
    // final userGymPreferences = await discoverRepository.getUserGymPreferences(event.userId, accessToken);
    final userProfiles = await discoverRepository.getDiscoveredUserProfiles(
        event.userId,
        accessToken,
        ConstantUtils.DEFAULT_LIMIT,
        ConstantUtils.DEFAULT_OFFSET
    );
    final doesNextPageExist = userProfiles.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

    emit(DiscoverUserDataFetched(
      discoveryPreferences: allUserPrefs.userDiscoveryPreferences,
      personalPreferences: allUserPrefs.userPersonalPreferences,
      fitnessPreferences: allUserPrefs.userFitnessPreferences,
      gymPreferences: allUserPrefs.userGymPreferences,
      discoveredUserProfiles: userProfiles,
      doesNextPageExist: doesNextPageExist,
    ));
  }
}