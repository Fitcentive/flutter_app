
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_event.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExerciseDiaryBloc extends Bloc<ExerciseDiaryEvent, ExerciseDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  ExerciseDiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const ExerciseDiaryStateInitial()) {
    on<FetchExerciseDiaryEntryInfo>(_fetchExerciseDiaryEntryInfo);
  }

  void _fetchExerciseDiaryEntryInfo(FetchExerciseDiaryEntryInfo event, Emitter<ExerciseDiaryState> emit) async {
    emit(const ExerciseDiaryDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final exerciseDefinition = await diaryRepository.getExerciseInfoByWorkoutId(event.workoutId, accessToken!);
    emit(ExerciseDiaryDataLoaded(exerciseDefinition: exerciseDefinition));
  }
}