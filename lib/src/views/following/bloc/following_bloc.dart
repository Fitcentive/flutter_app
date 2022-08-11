import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/following/bloc/following_event.dart';
import 'package:flutter_app/src/views/following/bloc/following_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowingBloc extends Bloc<FollowingEvent, FollowingState> {
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  FollowingBloc({
    required this.socialMediaRepository,
    required this.secureStorage
  }): super(const FollowingStateInitial()) {
    on<FetchFollowingUsersRequested>(_fetchFollowingUsersRequested);
    on<ReFetchFollowingUsersRequested>(_reFetchFollowingUsersRequested);
  }

  void _reFetchFollowingUsersRequested(ReFetchFollowingUsersRequested event, Emitter<FollowingState> emit) async {
    emit(FollowingUsersDataLoading(userId: event.userId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final followers =
    await socialMediaRepository.fetchUserFollowing(event.userId, accessToken!, event.limit, event.offset);
    final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
    emit(FollowingUsersDataLoaded(userId: event.userId, userProfiles: followers, doesNextPageExist: doesNextPageExist));
  }

  void _fetchFollowingUsersRequested(FetchFollowingUsersRequested event, Emitter<FollowingState> emit) async {
    final currentState = state;
    if (currentState is FollowingStateInitial) {
      emit(FollowingUsersDataLoading(userId: event.userId));
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final followers =
      await socialMediaRepository.fetchUserFollowing(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      emit(FollowingUsersDataLoaded(userId: event.userId, userProfiles: followers, doesNextPageExist: doesNextPageExist));
    }
    else if (currentState is FollowingUsersDataLoaded && currentState.doesNextPageExist) {
      // Avoid publishing loading event
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final followingUsers =
      await socialMediaRepository.fetchUserFollowing(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = followingUsers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      final completeFollowersList = [...currentState.userProfiles, ...followingUsers];
      emit(FollowingUsersDataLoaded(userId: event.userId, userProfiles: completeFollowersList, doesNextPageExist: doesNextPageExist));
    }
  }
}