import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/shared_components/liked_users/bloc/liked_users_event.dart';
import 'package:flutter_app/src/views/shared_components/liked_users/bloc/liked_users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LikedUsersBloc extends Bloc<LikedUsersEvent, LikedUsersState> {
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  LikedUsersBloc({required this.userRepository, required this.secureStorage}): super(const LikedUsersStateInitial()) {
    on<FetchedLikedUserProfiles>(_fetchedLikedUserProfiles);
  }

  void _fetchedLikedUserProfiles(FetchedLikedUserProfiles event, Emitter<LikedUsersState> emit) async {
    emit(const LikedUsersProfilesLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(event.userIds, accessToken!);
    emit(LikedUsersProfilesLoaded(userProfiles: userProfileDetails));
  }
}