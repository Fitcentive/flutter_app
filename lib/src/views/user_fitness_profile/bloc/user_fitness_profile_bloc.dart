import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/user_fitness_profile_event.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/user_fitness_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserFitnessProfileBloc extends Bloc<UserFitnessProfileEvent, UserFitnessProfileState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final UserRepository userRepository;

  UserFitnessProfileBloc({
    required this.diaryRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const UserFitnessProfileStateInitial()) {
    on<UpsertUserFitnessProfile>(_upsertUserFitnessProfile);
  }

  void _upsertUserFitnessProfile(UpsertUserFitnessProfile event, Emitter<UserFitnessProfileState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userFitnessProfile = await diaryRepository.upsertFitnessUserProfile(
        event.userId,
        FitnessUserProfileUpdate(
            heightInCm: event.heightInCm,
            weightInLbs: event.weightInLbs,
            goal: event.goal,
            activityLevel: event.activityLevel,
            stepGoalPerDay: event.stepGoalPerDay,
            goalWeightInLbs: event.goalWeightInLbs,
        ),
        accessToken!
    );
    userRepository.trackUserEvent(UpdateFitnessUserProfile(), accessToken);
    emit(UserFitnessProfileUpserted(fitnessUserProfile: userFitnessProfile));
  }

}
