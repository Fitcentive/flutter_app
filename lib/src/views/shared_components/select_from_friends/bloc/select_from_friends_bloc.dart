import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/bloc/select_from_friends_event.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/bloc/select_from_friends_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectFromFriendsBloc extends Bloc<SelectFromFriendsEvent, SelectFromFriendsState> {
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  SelectFromFriendsBloc({
    required this.socialMediaRepository,
    required this.secureStorage
  }): super(const SelectFromFriendsStateInitial()) {
    on<FetchFriendsRequested>(_fetchFriendsRequested);
    on<FetchFriendsByQueryRequested>(_fetchFriendByQueryRequested);
  }

  void _fetchFriendByQueryRequested(FetchFriendsByQueryRequested event, Emitter<SelectFromFriendsState> emit) async {
    final currentState = state;
    if (currentState is FriendsDataLoaded) {
      emit(FriendsDataLoading(userId: event.userId));
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final searchResults =
        await socialMediaRepository.searchUserFriends(event.userId, event.query, accessToken!, event.limit, event.offset);
      final doesNextPageExist = searchResults.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      emit(
          FriendsDataLoaded(
              userId: event.userId,
              userProfiles: searchResults,
              doesNextPageExist: doesNextPageExist
          )
      );
    }
  }

  void _fetchFriendsRequested(FetchFriendsRequested event, Emitter<SelectFromFriendsState> emit) async {
    final currentState = state;
    if (currentState is SelectFromFriendsStateInitial) {
      emit(FriendsDataLoading(userId: event.userId));
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final friends =
      await socialMediaRepository.fetchUserFriends(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = friends.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      emit(FriendsDataLoaded(userId: event.userId, userProfiles: friends, doesNextPageExist: doesNextPageExist));
    }
    else if (currentState is FriendsDataLoaded && currentState.doesNextPageExist) {
      // Avoid publishing loading event
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final friends =
      await socialMediaRepository.fetchUserFriends(event.userId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = friends.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      final completeFriendsList = [...currentState.userProfiles, ...friends];
      emit(FriendsDataLoaded(userId: event.userId, userProfiles: completeFriendsList, doesNextPageExist: doesNextPageExist));
    }
  }
}