import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/friends/bloc/friends_event.dart';
import 'package:flutter_app/src/views/friends/bloc/friends_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowersBloc extends Bloc<FriendsEvent, FollowersState> {
  final SocialMediaRepository socialMediaRepository;
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  FollowersBloc({
    required this.socialMediaRepository,
    required this.userRepository,
    required this.secureStorage}
      ): super(const FriendsStateInitial()) {
    on<TrackViewFriendsEvent>(_trackViewFriendsEvent);
    on<FetchFriendsRequested>(_fetchFriendsRequested);
    on<ReFetchFriendsRequested>(_reFetchFriendsRequested);
  }

  void _trackViewFriendsEvent(TrackViewFriendsEvent event, Emitter<FollowersState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(ViewFriends(), accessToken!);
  }

  void _reFetchFriendsRequested(ReFetchFriendsRequested event, Emitter<FollowersState> emit) async {
    emit(FriendsDataLoading(userId: event.userId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final followers =
    await socialMediaRepository.fetchUserFriends(event.userId, accessToken!, event.limit, event.offset);
    final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
    emit(FriendsDataLoaded(userId: event.userId, userProfiles: followers, doesNextPageExist: doesNextPageExist));
  }

  void _fetchFriendsRequested(FetchFriendsRequested event, Emitter<FollowersState> emit) async {
    final currentState = state;
    if (currentState is FriendsStateInitial) {
      emit(FriendsDataLoading(userId: event.userId));
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final followers =
      await socialMediaRepository.fetchUserFriends(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      emit(FriendsDataLoaded(userId: event.userId, userProfiles: followers, doesNextPageExist: doesNextPageExist));
    }
    else if (currentState is FriendsDataLoaded && currentState.doesNextPageExist) {
      // Avoid publishing loading event
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final followers =
      await socialMediaRepository.fetchUserFriends(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      final completeFollowersList = [...currentState.userProfiles, ...followers];
      emit(FriendsDataLoaded(userId: event.userId, userProfiles: completeFollowersList, doesNextPageExist: doesNextPageExist));
    }
  }
}