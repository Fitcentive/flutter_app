import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_event.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowersBloc extends Bloc<FollowersEvent, FollowersState> {
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  FollowersBloc({required this.socialMediaRepository, required this.secureStorage}): super(const FollowersStateInitial()) {
    on<FetchFollowersRequested>(_fetchFollowersRequested);
    on<ReFetchFollowersRequested>(_reFetchFollowersRequested);
  }

  void _reFetchFollowersRequested(ReFetchFollowersRequested event, Emitter<FollowersState> emit) async {
    emit(FollowersDataLoading(userId: event.userId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final followers =
    await socialMediaRepository.fetchUserFollowers(event.userId, accessToken!, event.limit, event.offset);
    final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
    emit(FollowersDataLoaded(userId: event.userId, userProfiles: followers, doesNextPageExist: doesNextPageExist));
  }

  void _fetchFollowersRequested(FetchFollowersRequested event, Emitter<FollowersState> emit) async {
    final currentState = state;
    if (currentState is FollowersStateInitial) {
      emit(FollowersDataLoading(userId: event.userId));
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final followers =
      await socialMediaRepository.fetchUserFollowers(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      emit(FollowersDataLoaded(userId: event.userId, userProfiles: followers, doesNextPageExist: doesNextPageExist));
    }
    else if (currentState is FollowersDataLoaded && currentState.doesNextPageExist) {
      // Avoid publishing loading event
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final followers =
      await socialMediaRepository.fetchUserFollowers(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = followers.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      final completeFollowersList = [...currentState.userProfiles, ...followers];
      emit(FollowersDataLoaded(userId: event.userId, userProfiles: completeFollowersList, doesNextPageExist: doesNextPageExist));
    }
  }
}