import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/detailed_exercise/bloc/detailed_exercise_event.dart';
import 'package:flutter_app/src/views/detailed_exercise/bloc/detailed_exercise_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedExerciseBloc extends Bloc<DetailedExerciseEvent, DetailedExerciseState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  DetailedExerciseBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const DetailedExerciseStateInitial()) {
    on<AddCurrentExerciseToUserMostRecentlyViewed>(_addCurrentExerciseToUserMostRecentlyViewed);
  }

  void _addCurrentExerciseToUserMostRecentlyViewed(
      AddCurrentExerciseToUserMostRecentlyViewed event,
      Emitter<DetailedExerciseState> emit
  ) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.addUserMostRecentlyViewedWorkouts(event.currentUserId, event.currentExerciseId, accessToken!);
  }

}