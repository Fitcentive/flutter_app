import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/views/discovery_radius/bloc/discovery_radius_event.dart';
import 'package:flutter_app/src/views/discovery_radius/bloc/discovery_radius_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoveryRadiusBloc extends Bloc<DiscoveryRadiusEvent, DiscoveryRadiusState> {
  final UserRepository userRepository;
  final AuthenticatedUserStreamRepository authUserStreamRepository;
  final FlutterSecureStorage secureStorage;

  DiscoveryRadiusBloc({
    required this.userRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
  }) : super(const InitialState()) {
    on<LocationInfoChanged>(_locationInfoChanged);
    on<LocationInfoSubmitted>(_locationInfoSubmitted);
  }

  void _locationInfoChanged(LocationInfoChanged event, Emitter<DiscoveryRadiusState> emit) async {
    emit(LocationInfoModified(user: event.user, selectedCoordinates: event.coordinates, radius: event.radius));
  }

  void _locationInfoSubmitted(LocationInfoSubmitted event, Emitter<DiscoveryRadiusState> emit) async {
    final updateUserProfile = UpdateUserProfile(
        locationCenter: Coordinates(event.coordinates.latitude, event.coordinates.longitude),
        locationRadius: event.radius
    );
    const updateUser = UpdateUserPatch(accountStatus: "LoginReady");
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final userProfile = await userRepository.createOrUpdateUserProfile(event.user.user.id, updateUserProfile, accessToken!);
    final updatedUser = await userRepository.updateUserPatch(event.user.user.id, updateUser, accessToken);
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: updatedUser,
        userAgreements: event.user.userAgreements,
        userProfile: userProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);
    emit(const LocationInfoUpdated());
  }
}