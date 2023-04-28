import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/update_user_fitness_profile_event.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/update_user_fitness_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateUserFitnessProfileBloc extends Bloc<CreateUserFitnessProfileEvent, CreateUserFitnessProfileState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  CreateUserFitnessProfileBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const CreateUserFitnessProfileStateInitial()) {
    on<UpsertUserFitnessProfile>(_upsertUserFitnessProfile);
  }

  void _upsertUserFitnessProfile(UpsertUserFitnessProfile event, Emitter<CreateUserFitnessProfileState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userFitnessProfile = await diaryRepository.upsertFitnessUserProfile(
        event.userId,
        FitnessUserProfileUpdate(heightInCm: event.heightInCm, weightInLbs: event.weightInLbs),
        accessToken!
    );
    emit(UserFitnessProfileUpserted(fitnessUserProfile: userFitnessProfile));
  }

}
