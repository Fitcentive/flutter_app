import 'package:either_dart/either.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
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
    on<StrengthExerciseDiaryEntryUpdated>(_strengthExerciseDiaryEntryUpdated);
    on<CardioExerciseDiaryEntryUpdated>(_cardioExerciseDiaryEntryUpdated);
  }

  void _cardioExerciseDiaryEntryUpdated(CardioExerciseDiaryEntryUpdated event, Emitter<ExerciseDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.updateCardioUserDiaryEntry(event.userId, event.cardioDiaryEntryId, event.entry, accessToken!);
    emit(const ExerciseEntryUpdatedAndReadyToPop());
  }

  void _strengthExerciseDiaryEntryUpdated(StrengthExerciseDiaryEntryUpdated event, Emitter<ExerciseDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.updateStrengthUserDiaryEntry(event.userId, event.strengthDiaryEntryId, event.entry, accessToken!);
    emit(const ExerciseEntryUpdatedAndReadyToPop());
  }


  void _fetchExerciseDiaryEntryInfo(FetchExerciseDiaryEntryInfo event, Emitter<ExerciseDiaryState> emit) async {
    emit(const ExerciseDiaryDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final exerciseDefinition = await diaryRepository.getExerciseInfoByWorkoutId(event.workoutId, accessToken!);
    final Either<CardioDiaryEntry, StrengthDiaryEntry> diaryEntry;

    if (event.isCardio) {
      diaryEntry = Left((await diaryRepository.getCardioUserDiaryEntry(event.userId, event.diaryEntryId, accessToken)));
    }
    else {
      diaryEntry = Right((await diaryRepository.getStrengthUserDiaryEntry(event.userId, event.diaryEntryId, accessToken)));
    }

    emit(
        ExerciseDiaryDataLoaded(
          exerciseDefinition: exerciseDefinition,
          diaryEntry: diaryEntry
        )
    );
  }
}