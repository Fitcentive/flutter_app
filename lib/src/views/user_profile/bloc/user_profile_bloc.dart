import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserRepository userRepository;
  final FlutterSecureStorage flutterSecureStorage;

  UserProfileBloc({required this.userRepository, required this.flutterSecureStorage})
      : super(const UserProfileInitial()) {
    on<FetchRequiredData>(_fetchRequiredData);
    on<RequestToFollowUser>(_requestToFollowUser);
  }

  void _fetchRequiredData(FetchRequiredData event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final username = await userRepository.getUserUsername(event.userId, accessToken!);
    final hasCurrentUserAlreadyRequestedToFollowTargetUser = await userRepository
        .checkIfUserHasRequestedToFollowOtherUser(event.currentUser.user.id, event.userId, accessToken);
    emit(RequiredDataResolved(
        username: username,
        hasCurrentUserAlreadyRequestedToFollowUser: hasCurrentUserAlreadyRequestedToFollowTargetUser));
  }

  void _requestToFollowUser(RequestToFollowUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.requestToFollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    emit(RequiredDataResolved(
        username: event.resolvedUsername,
        hasCurrentUserAlreadyRequestedToFollowUser: event.hasCurrentUserAlreadyRequestedToFollowUser
    ));
  }
}
