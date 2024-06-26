import 'package:flutter_app/src/infrastructure/repos/rest/awards_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/detailed_progress_view/bloc/detailed_progress_event.dart';
import 'package:flutter_app/src/views/detailed_progress_view/bloc/detailed_progress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedProgressBloc extends Bloc<DetailedProgressEvent, DetailedProgressState> {
  final FlutterSecureStorage secureStorage;
  final AwardsRepository awardsRepository;
  final UserRepository userRepository;

  bool isFirstLoad = true;

  DetailedProgressBloc({
    required this.awardsRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const DetailedProgressStateInitial()) {
    on<FetchDataForMetricCategory>(_fetchDataForMetricCategory);
  }

  void _fetchDataForMetricCategory(FetchDataForMetricCategory event, Emitter<DetailedProgressState> emit) async {
    if (isFirstLoad) {
      emit(const DetailedProgressLoading());
      isFirstLoad = false;
    }
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    if (event.category.name() == StepData().name()) {
      userRepository.trackUserEvent(ViewDetailedStepProgress(), accessToken!);
      final metrics = await awardsRepository.getUserStepProgressData(event.from, event.to, accessToken);
      emit(StepProgressMetricsLoaded(userStepMetrics: metrics));
    }
    else if (event.category.name() == DiaryEntryData().name()) {
      userRepository.trackUserEvent(ViewDetailedDiaryProgress(), accessToken!);
      final metrics = await awardsRepository.getUserDiaryEntryProgressData(event.from, event.to, accessToken);
      emit(DiaryEntriesProgressMetricsLoaded(userDiaryEntryMetrics: metrics));
    }
    else if (event.category.name() == ActivityData().name()) {
      userRepository.trackUserEvent(ViewDetailedActivityProgress(), accessToken!);
      final metrics = await awardsRepository.getUserActivityProgressData(event.from, event.to, accessToken);
      emit(ActivityProgressMetricsLoaded(userActivityMetrics: metrics));
    }
    else if (event.category.name() == WeightData().name()) {
      userRepository.trackUserEvent(ViewDetailedWeightProgress(), accessToken!);
      final metrics = await awardsRepository.getUserWeightProgressData(event.from, event.to, accessToken);
      emit(WeightProgressMetricsLoaded(userWeightMetrics: metrics));
    }

  }

}