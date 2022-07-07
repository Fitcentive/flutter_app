import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/following/bloc/following_event.dart';
import 'package:flutter_app/src/views/following/bloc/following_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowingBloc extends Bloc<FollowingEvent, FollowingState> {
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  FollowingBloc({
    required this.userRepository,
    required this.secureStorage
  }): super(const FollowingStateInitial()) {
    on<FetchFollowingUsersRequested>(_fetchFollowingUsersRequested);
  }

  void _fetchFollowingUsersRequested(FetchFollowingUsersRequested event, Emitter<FollowingState> emit) async {
    emit(FollowingUsersDataLoading(userId: event.userId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final followers = await userRepository.fetchUserFollowing(event.userId, accessToken!);
    emit(FollowingUsersDataLoaded(userId: event.userId, userProfiles: followers));
  }
}