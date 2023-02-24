import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/exercise_search/bloc/exercise_search_event.dart';
import 'package:flutter_app/src/views/exercise_search/bloc/exercise_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExerciseSearchBloc extends Bloc<ExerciseSearchEvent, ExerciseSearchState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  ExerciseSearchBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const ExerciseSearchStateInitial()) {
    on<FetchAllExerciseInfo>(_fetchAllExerciseInfo);
    on<FilterSearchQueryChanged>(_filterSearchQueryChanged);
  }

  void _fetchAllExerciseInfo(FetchAllExerciseInfo event, Emitter<ExerciseSearchState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final info = await diaryRepository.getAllExerciseInfo(accessToken!);
    emit(ExerciseDataFetched(
        allExerciseInfo: info,
        filteredExerciseInfo: info
    ));
  }

  // todo - Very poor perf on exercise api/filtering
  void _filterSearchQueryChanged(FilterSearchQueryChanged event, Emitter<ExerciseSearchState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final info = await diaryRepository.getAllExerciseInfo(accessToken!);

    if (state is ExerciseDataFetched) {
      final filteredList = event.searchQuery.isEmpty ? info :
        info.where((element) => element.name.toLowerCase().contains(event.searchQuery.toLowerCase())).toList();
      emit(ExerciseDataFetched(
          allExerciseInfo: info,
          filteredExerciseInfo: filteredList
      ));
    }
  }
}