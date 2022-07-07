import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_event.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowersBloc extends Bloc<FollowersEvent, FollowersState> {
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  FollowersBloc({required this.userRepository, required this.secureStorage}): super(const FollowersStateInitial()) {
    on<FetchFollowersRequested>(_fetchFollowersRequested);
  }

  void _fetchFollowersRequested(FetchFollowersRequested event, Emitter<FollowersState> emit) async {
    emit(FollowersDataLoading(userId: event.userId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final followers = await userRepository.fetchUserFollowers(event.userId, accessToken!);
    emit(FollowersDataLoaded(userId: event.userId, userProfiles: followers));
  }
}