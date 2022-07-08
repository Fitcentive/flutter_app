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
    on<UnfollowUser>(_unfollowUser);
    on<RemoveUserFromCurrentUserFollowers>(_removeUserFromCurrentUserFollowers);
    on<ApplyUserDecisionToFollowRequest>(_applyUserDecisionToFollowRequest);
  }

  void _fetchRequiredData(FetchRequiredData event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userFollowStatus =
        await userRepository.getUserFollowStatus(event.currentUser.user.id, event.userId, accessToken!);
    emit(RequiredDataResolved(userFollowStatus: userFollowStatus));
  }

  void _requestToFollowUser(RequestToFollowUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.requestToFollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    print(userFollowStatus.toString());
    emit(RequiredDataResolved(userFollowStatus: userFollowStatus));
  }

  void _unfollowUser(UnfollowUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.unfollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(userFollowStatus: userFollowStatus));
  }

  void _removeUserFromCurrentUserFollowers(RemoveUserFromCurrentUserFollowers event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.removeFollowingUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(userFollowStatus: userFollowStatus));
  }

  void _applyUserDecisionToFollowRequest(ApplyUserDecisionToFollowRequest event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.applyUserDecisionToFollowRequest(
        event.targetUserId,
        event.currentUser.user.id,
        event.isFollowRequestApproved,
        accessToken!
    );
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(userFollowStatus: userFollowStatus));
  }
}
