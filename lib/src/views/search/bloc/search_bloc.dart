
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/search/bloc/search_event.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final DiaryRepository diaryRepository;
  final FlutterSecureStorage secureStorage;

  SearchBloc({
    required this.diaryRepository,
    required this.secureStorage
  }) : super(const SearchStateInitial()) {
    on<FetchFitnessUserProfile>(_fetchFitnessUserProfile);
  }

  void _fetchFitnessUserProfile(FetchFitnessUserProfile event, Emitter<SearchState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final profile = await diaryRepository.getFitnessUserProfile(event.currentUserId, accessToken!);
    emit(UserFitnessProfileFetched(fitnessUserProfile: profile));
  }
}