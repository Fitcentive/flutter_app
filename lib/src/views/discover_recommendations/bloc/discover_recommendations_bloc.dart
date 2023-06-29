import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_event.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverRecommendationsBloc extends Bloc<DiscoverRecommendationsEvent, DiscoverRecommendationsState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;
  final UserRepository userRepository;

  DiscoverRecommendationsBloc({
    required this.discoverRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const DiscoverRecommendationsStateInitial()) {
    on<FetchUserDiscoverRecommendations>(_fetchUserDiscoverRecommendations);
    on<UpsertNewlyDiscoveredUser>(_upsertNewlyDiscoveredUser);
    on<TrackRejectNewDiscoveredUserEvent>(_trackRejectNewDiscoveredUserEvent);
  }

  void _trackRejectNewDiscoveredUserEvent(TrackRejectNewDiscoveredUserEvent event, Emitter<DiscoverRecommendationsState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(RejectNewDiscoveredUser(), accessToken!);
  }

  void _upsertNewlyDiscoveredUser(UpsertNewlyDiscoveredUser event, Emitter<DiscoverRecommendationsState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await discoverRepository.upsertDiscoveredUser(event.currentUserId, event.newUserId, accessToken!);
    userRepository.trackUserEvent(AcceptNewDiscoveredUser(), accessToken);
  }

  void _fetchUserDiscoverRecommendations(FetchUserDiscoverRecommendations event, Emitter<DiscoverRecommendationsState> emit) async {
    emit(const DiscoverRecommendationsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final recommendations = await discoverRepository.getUserDiscoverRecommendations(
        event.currentUserProfile.userId,
        event.isPremiumEnabled ? null : ConstantUtils.MAX_DISCOVERABLE_USERS_PER_MONTH_FREE,
        accessToken!
    );
    userRepository.trackUserEvent(AttemptToDiscoverUsers(), accessToken);
    emit(DiscoverRecommendationsReady(currentUserProfile: event.currentUserProfile, recommendations: recommendations));
  }
}