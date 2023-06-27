import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/bloc/select_from_diary_entries_event.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/bloc/select_from_diary_entries_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class SelectFromDiaryEntriesBloc extends Bloc<SelectFromDiaryEntriesEvent, SelectFromDiaryEntriesState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  SelectFromDiaryEntriesBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const SelectFromDiaryEntriesInitialState()) {
    on<SelectFromDiaryEntriesFetchInfoEvent>(_selectFromDiaryEntriesFetchInfoEvent);
  }

  void _selectFromDiaryEntriesFetchInfoEvent(SelectFromDiaryEntriesFetchInfoEvent event, Emitter<SelectFromDiaryEntriesState> emit) async {
    final currentState = state;
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final entries = await diaryRepository.getAllDiaryEntriesForUserByDay(
        event.userId,
        DateFormat("yyyy-MM-dd").format(event.diaryDate),
        DateTime.now().timeZoneOffset.inMinutes,
        accessToken!
    );
    final foodEntries = await Future.wait(entries.foodEntries.map((e) => diaryRepository.getFoodById(e.foodId.toString(), accessToken)));

    if (currentState is SelectFromDiaryEntriesDiaryDataFetched) {
      emit(SelectFromDiaryEntriesDiaryDataFetched(
          strengthDiaryEntries: entries.strengthWorkouts,
          cardioDiaryEntries: entries.cardioWorkouts,
          foodDiaryEntriesRaw: entries.foodEntries,
          foodDiaryEntries: foodEntries,
          fitnessUserProfile: currentState.fitnessUserProfile
      ));
    }
    else {
      final fitnessUserProfile = await diaryRepository.getFitnessUserProfile(event.userId, accessToken);
      emit(SelectFromDiaryEntriesDiaryDataFetched(
          strengthDiaryEntries: entries.strengthWorkouts,
          cardioDiaryEntries: entries.cardioWorkouts,
          foodDiaryEntriesRaw: entries.foodEntries,
          foodDiaryEntries: foodEntries,
          fitnessUserProfile: fitnessUserProfile
      ));
    }
  }


}
