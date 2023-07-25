import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final UserRepository userRepository;

  DiaryBloc({
    required this.diaryRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const DiaryStateInitial()) {
    on<TrackViewDiaryHomeEvent>(trackViewDiaryHomeEvent);
    on<FetchDiaryInfo>(_fetchDiaryInfo);
    on<RemoveFoodDiaryEntryFromDiary>(_removeFoodDiaryEntryFromDiary);
    on<RemoveCardioDiaryEntryFromDiary>(_removeCardioDiaryEntryFromDiary);
    on<RemoveStrengthDiaryEntryFromDiary>(_removeStrengthDiaryEntryFromDiary);
    on<UserFitnessProfileUpdated>(_userFitnessProfileUpdated);
  }

  void trackViewDiaryHomeEvent(TrackViewDiaryHomeEvent event, Emitter<DiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(ViewDiaryHome(), accessToken!);
  }

  void _userFitnessProfileUpdated(UserFitnessProfileUpdated event, Emitter<DiaryState> emit) async {
    final currentState = state;
    if (currentState is DiaryDataFetched) {
      emit(DiaryDataFetched(
          strengthDiaryEntries: currentState.strengthDiaryEntries,
          cardioDiaryEntries: currentState.cardioDiaryEntries,
          foodDiaryEntriesRaw: currentState.foodDiaryEntriesRaw,
          foodDiaryEntries: currentState.foodDiaryEntries,
          fitnessUserProfile: event.fitnessUserProfile,
          userStepsData: currentState.userStepsData,
      ));
    }
  }

  void _removeFoodDiaryEntryFromDiary(RemoveFoodDiaryEntryFromDiary event, Emitter<DiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.deleteFoodEntryFromUserDiary(event.userId, event.foodDiaryEntryId, accessToken!);
  }

  void _removeCardioDiaryEntryFromDiary(RemoveCardioDiaryEntryFromDiary event, Emitter<DiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.deleteCardioEntryFromUserDiary(event.userId, event.cardioDiaryEntryId, accessToken!);
  }

  void _removeStrengthDiaryEntryFromDiary(RemoveStrengthDiaryEntryFromDiary event, Emitter<DiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.deleteStrengthEntryFromUserDiary(event.userId, event.strengthDiaryEntryId, accessToken!);
  }


  void _fetchDiaryInfo(FetchDiaryInfo event, Emitter<DiaryState> emit) async {
    final currentState = state;
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final entries = await diaryRepository.getAllDiaryEntriesForUserByDay(
        event.userId,
        DateFormat("yyyy-MM-dd").format(event.diaryDate),
        DateTime.now().timeZoneOffset.inMinutes,
        accessToken!
    );
    // final cardioWorkouts = await diaryRepository.getCardioWorkoutsForUserByDay(
    //     event.userId,
    //     DateFormat("yyyy-MM-dd").format(event.diaryDate),
    //     DateTime.now().timeZoneOffset.inMinutes,
    //     accessToken!
    // );
    // final strengthWorkouts = await diaryRepository.getStrengthWorkoutsForUserByDay(
    //     event.userId,
    //     DateFormat("yyyy-MM-dd").format(event.diaryDate),
    //     DateTime.now().timeZoneOffset.inMinutes,
    //     accessToken
    // );
    //
    // final foodEntriesRaw = await diaryRepository.getFoodEntriesForUserByDay(
    //     event.userId,
    //     DateFormat("yyyy-MM-dd").format(event.diaryDate),
    //     DateTime.now().timeZoneOffset.inMinutes,
    //     accessToken
    // );
    final foodEntries = await Future.wait(entries.foodEntries.map((e) => diaryRepository.getFoodById(e.foodId.toString(), accessToken)));

    final stepsData = await diaryRepository.getUserStepsData(event.userId, DateFormat('yyyy-MM-dd').format(event.diaryDate), accessToken);

    if (currentState is DiaryDataFetched) {
      emit(DiaryDataFetched(
          strengthDiaryEntries: entries.strengthWorkouts,
          cardioDiaryEntries: entries.cardioWorkouts,
          foodDiaryEntriesRaw: entries.foodEntries,
          foodDiaryEntries: foodEntries,
          fitnessUserProfile: currentState.fitnessUserProfile,
          userStepsData: stepsData,
      ));
    }
    else {
      final fitnessUserProfile = await diaryRepository.getFitnessUserProfile(event.userId, accessToken);
      emit(DiaryDataFetched(
          strengthDiaryEntries: entries.strengthWorkouts,
          cardioDiaryEntries: entries.cardioWorkouts,
          foodDiaryEntriesRaw: entries.foodEntries,
          foodDiaryEntries: foodEntries,
          fitnessUserProfile: fitnessUserProfile,
          userStepsData: stepsData,
      ));
    }

  }

}