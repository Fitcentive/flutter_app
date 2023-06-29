import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/search/bloc/activity_search/activity_event.dart';
import 'package:flutter_app/src/views/search/bloc/activity_search/activity_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActivitySearchBloc extends Bloc<ActivitySearchEvent, ActivitySearchState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final UserRepository userRepository;

  ActivitySearchBloc({
    required this.diaryRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const ActivitySearchStateInitial()) {
    on<FetchAllActivityInfo>(_fetchAllActivityInfo);
    on<ActivityFilterSearchQueryChanged>(_activityFilterSearchQueryChanged);
  }

  void _fetchAllActivityInfo(FetchAllActivityInfo event, Emitter<ActivitySearchState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final info = await diaryRepository.getAllExerciseInfo(accessToken!);
    userRepository.trackUserEvent(SearchForExercise(), accessToken);
    emit(ActivityDataFetched(
        allExerciseInfo: info,
        filteredExerciseInfo: info
    ));
  }

  void _activityFilterSearchQueryChanged(ActivityFilterSearchQueryChanged event, Emitter<ActivitySearchState> emit) async {
    final currentState = state;

    if (currentState is ActivityDataFetched) {
      emit(const ActivityDataLoading());
      final filteredList = event.searchQuery.isEmpty ?
        currentState.allExerciseInfo :
        currentState.allExerciseInfo
            .where((element) => element.name.toLowerCase().contains(event.searchQuery.toLowerCase()))
            .toList();

      emit(ActivityDataFetched(
          allExerciseInfo: currentState.allExerciseInfo,
          filteredExerciseInfo: filteredList
      ));
    }
  }
}