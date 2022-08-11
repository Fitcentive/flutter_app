import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/search/bloc/search_event.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
import 'package:flutter_app/src/views/search/views/user_search_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  SearchBloc({
    required this.userRepository,
    required this.secureStorage
  }): super(const SearchStateInitial()) {
    on<SearchQueryChanged>(_searchQueryChanged);
    on<SearchQueryReset>(_searchQueryReset);
    on<SearchQuerySubmitted>(_searchQuerySubmitted);
  }

  void _searchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    emit(SearchQueryModified(query: event.query));
  }

  void _searchQueryReset(SearchQueryReset event, Emitter<SearchState> emit) async {
    emit(const SearchQueryModified(query: ""));
  }

  void _searchQuerySubmitted(SearchQuerySubmitted event, Emitter<SearchState> emit) async {
   final currentState = state;
   if (currentState is SearchStateInitial || currentState is SearchQueryModified) {
     emit(SearchResultsLoading(query: event.query));
     try {
       final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
       final results = await userRepository.searchForUsers(event.query, accessToken!, event.limit, event.offset);
       final doesNextPageExist = results.length == UserSearchViewState.DEFAULT_LIMIT ? true : false;
       emit(SearchResultsLoaded(query: event.query, userData: results, doesNextPageExist: doesNextPageExist));
     } catch (ex) {
       emit(SearchResultsError(query: event.query, error: ex.toString()));
     }
   }
   else if (currentState is SearchResultsLoaded && currentState.doesNextPageExist) {
     try {
       final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
       final results = await userRepository.searchForUsers(event.query, accessToken!, event.limit, event.offset);
       final doesNextPageExist = results.length == UserSearchViewState.DEFAULT_LIMIT ? true : false;
       final completeResults = [...currentState.userData, ...results];
       emit(SearchResultsLoaded(query: event.query, userData: completeResults, doesNextPageExist: doesNextPageExist));
     } catch (ex) {
       emit(SearchResultsError(query: event.query, error: ex.toString()));
     }
   }

  }
}