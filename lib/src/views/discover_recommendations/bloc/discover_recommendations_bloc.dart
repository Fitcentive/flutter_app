import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_event.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverRecommendationsBloc extends Bloc<DiscoverRecommendationsEvent, DiscoverRecommendationsState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;

  DiscoverRecommendationsBloc({
    required this.discoverRepository,
    required this.secureStorage,
  }) : super(const DiscoverRecommendationsStateInitial()) {
    on<FetchUserDiscoverRecommendations>(_fetchUserDiscoverRecommendations);
    on<UpsertNewlyDiscoveredUser>(_upsertNewlyDiscoveredUser);
  }

  void _upsertNewlyDiscoveredUser(UpsertNewlyDiscoveredUser event, Emitter<DiscoverRecommendationsState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await discoverRepository.upsertDiscoveredUser(event.currentUserId, event.newUserId, accessToken!);
  }

  void _fetchUserDiscoverRecommendations(FetchUserDiscoverRecommendations event, Emitter<DiscoverRecommendationsState> emit) async {
    emit(const DiscoverRecommendationsLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final recommendations = await discoverRepository.getUserDiscoverRecommendations(event.currentUserProfile.userId, accessToken!);
    emit(DiscoverRecommendationsReady(currentUserProfile: event.currentUserProfile, recommendations: recommendations));
  }
}