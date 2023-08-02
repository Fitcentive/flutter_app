import 'package:flutter_app/src/infrastructure/repos/rest/awards_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/progress/bloc/progress_home_event.dart';
import 'package:flutter_app/src/views/progress/bloc/progress_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProgressHomeBloc extends Bloc<ProgressHomeEvent, ProgressHomeState> {
  final FlutterSecureStorage secureStorage;
  final AwardsRepository awardsRepository;
  final UserRepository userRepository;
  final DiaryRepository diaryRepository;

  bool isFirstTime = true;

  ProgressHomeBloc({
    required this.awardsRepository,
    required this.userRepository,
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const ProgressStateInitial()) {
    on<FetchProgressInsights>(_fetchProgressInsights);
  }

  void _fetchProgressInsights(FetchProgressInsights event, Emitter<ProgressHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    if (isFirstTime) {
      userRepository.trackUserEvent(ViewProgress(), accessToken!);
      isFirstTime = false;
    }

    final insightsFut = awardsRepository.getUserProgressInsights(accessToken!, DateTime.now().timeZoneOffset.inMinutes);
    final fitnessUserProfileFut = diaryRepository.getFitnessUserProfile(event.userId, accessToken!);

    final insights = await insightsFut;
    final fitnessUserProfile = await fitnessUserProfileFut;

    emit(
        ProgressLoaded(
            insights: insights,
            fitnessUserProfile: fitnessUserProfile,
        )
    );
  }

}