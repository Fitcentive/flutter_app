import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  DiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const DiaryStateInitial()) {
    on<FetchDiaryInfo>(_fetchDiaryInfo);
  }

  void _fetchDiaryInfo(FetchDiaryInfo event, Emitter<DiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final cardioWorkouts = await diaryRepository.getCardioWorkoutsForUserByDay(
        event.userId,
        DateFormat("yyyy-MM-dd").format(event.diaryDate),
        accessToken!
    );
    final strengthWorkouts = await diaryRepository.getStrengthWorkoutsForUserByDay(
        event.userId,
        DateFormat("yyyy-MM-dd").format(event.diaryDate),
        accessToken
    );

    final foodEntriesRaw = await diaryRepository.getFoodEntriesForUserByDay(
        event.userId,
        DateFormat("yyyy-MM-dd").format(event.diaryDate),
        accessToken
    );
    final foodEntries = await Future.wait(foodEntriesRaw.map((e) => diaryRepository.getFoodById(e.foodId.toString(), accessToken)));

    emit(DiaryDataFetched(
      strengthDiaryEntries: strengthWorkouts,
      cardioDiaryEntries: cardioWorkouts,
      foodDiaryEntriesRaw: foodEntriesRaw,
      foodDiaryEntries: foodEntries,
    ));
  }

}