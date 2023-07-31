import 'package:flutter_app/src/infrastructure/repos/rest/awards_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/achievements/bloc/achievements_home_event.dart';
import 'package:flutter_app/src/views/achievements/bloc/achievements_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AchievementsHomeBloc extends Bloc<AchievementsHomeEvent, AchievementsHomeState> {
  final FlutterSecureStorage secureStorage;
  final AwardsRepository awardsRepository;
  final UserRepository userRepository;

  AchievementsHomeBloc({
    required this.awardsRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const AchievementsStateInitial()) {
    on<FetchAllUserAchievements>(_fetchAllUserAchievements);
  }

  void _fetchAllUserAchievements(FetchAllUserAchievements event, Emitter<AchievementsHomeState> emit) async {
    emit(const AchievementsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final allAchievements = await awardsRepository.getAllUserAchievements(accessToken!);
    emit(AchievementsLoadedSuccess(userMilestones: allAchievements));
  }

}