import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/search_event.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final UserRepository userRepository;
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  SearchBloc({
    required this.userRepository,
    required this.socialMediaRepository,
    required this.secureStorage
  }): super(const SearchStateInitial()) {
    on<FetchUserFriends>(_fetchUserFriends);
    on<SearchQueryChanged>(_searchQueryChanged);
    on<SearchQueryReset>(_searchQueryReset);
    on<SearchQuerySubmitted>(_searchQuerySubmitted);
  }

  void _fetchUserFriends(FetchUserFriends event, Emitter<SearchState> emit) async {
    try {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final friends = await socialMediaRepository.fetchUserFriends(event.currentUserId, accessToken!, event.limit, event.offset);
      final doesNextPageExist = friends.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
      emit(SearchResultsLoaded(query: "", userData: friends, doesNextPageExist: doesNextPageExist));
    } catch (ex) {
      emit(SearchResultsError(query: "", error: ex.toString()));
    }
  }

  void _searchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    emit(SearchQueryModified(query: event.query));
  }

  void _searchQueryReset(SearchQueryReset event, Emitter<SearchState> emit) async {
    emit(const SearchQueryModified(query: ""));
    add(FetchUserFriends(currentUserId: event.currentUserId, limit: ConstantUtils.DEFAULT_LIMIT, offset: ConstantUtils.DEFAULT_OFFSET));
  }

  void _searchQuerySubmitted(SearchQuerySubmitted event, Emitter<SearchState> emit) async {
   final currentState = state;
   if (currentState is SearchStateInitial || currentState is SearchQueryModified) {
     emit(SearchResultsLoading(query: event.query));
     try {
       final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
       final results = await userRepository.searchForUsers(event.query, accessToken!, event.limit, event.offset);
       final doesNextPageExist = results.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
       emit(SearchResultsLoaded(query: event.query, userData: results, doesNextPageExist: doesNextPageExist));
     } catch (ex) {
       emit(SearchResultsError(query: event.query, error: ex.toString()));
     }
   }
   else if (currentState is SearchResultsLoaded && currentState.doesNextPageExist) {
     try {
       final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
       final results = await userRepository.searchForUsers(event.query, accessToken!, event.limit, event.offset);
       final doesNextPageExist = results.length == ConstantUtils.DEFAULT_LIMIT ? true : false;
       final completeResults = [...currentState.userData, ...results];
       emit(SearchResultsLoaded(query: event.query, userData: completeResults, doesNextPageExist: doesNextPageExist));
     } catch (ex) {
       emit(SearchResultsError(query: event.query, error: ex.toString()));
     }
   }

  }
}