import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/search/bloc/search_event.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
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
    emit(SearchResultsLoading(query: event.query));
    // todo - send results
    emit(SearchResultsLoaded(query: event.query, userData: List.empty()));
  }
}