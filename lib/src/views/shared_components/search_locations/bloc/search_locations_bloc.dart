import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_event.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchLocationsBloc extends Bloc<SearchLocationsEvent, SearchLocationsState> {
  final MeetupRepository meetupRepository;
  final FlutterSecureStorage secureStorage;

  SearchLocationsBloc({
    required this.meetupRepository,
    required this.secureStorage
  }): super(const SearchLocationsStateInitial()) {
    on<SearchLocationsQueryChanged>(_searchLocationsQueryChanged);
    on<SearchLocationsQueryReset>(_searchLocationsQueryReset);
    on<SearchLocationsQuerySubmitted>(_searchLocationsQuerySubmitted);
    on<FetchLocationsAroundCoordinatesRequested>(_fetchLocationsAroundCoordinatesRequested);
  }

  void _fetchLocationsAroundCoordinatesRequested(
      FetchLocationsAroundCoordinatesRequested event,
      Emitter<SearchLocationsState> emit
  ) async {
    try {
      emit(
          FetchLocationsAroundCoordinatesLoading(
              query: event.query,
              coordinates: event.coordinates,
              radiusInMetres: event.radiusInMetres
          )
      );
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final results = await meetupRepository.getGymsAroundLocation(event.query, event.coordinates, event.radiusInMetres, accessToken!);
      emit(
          FetchLocationsAroundCoordinatesLoaded(
              query: event.query,
              locationResults: results,
              coordinates: event.coordinates,
              radiusInMetres: event.radiusInMetres
          )
      );
    } catch (ex) {
      emit(FetchLocationsAroundCoordinatesError(
          query: event.query,
          coordinates: event.coordinates,
          radiusInMetres: event.radiusInMetres,
          error: ex.toString()
      ));
    }
  }

  void _searchLocationsQueryChanged(SearchLocationsQueryChanged event, Emitter<SearchLocationsState> emit) async {
    emit(SearchLocationsQueryModified(
        query: event.query,
        coordinates: event.coordinates,
        radiusInMetres: event.radiusInMetres
    ));
  }

  void _searchLocationsQueryReset(SearchLocationsQueryReset event, Emitter<SearchLocationsState> emit) async {
    emit(SearchLocationsQueryModified(
        query: "",
        coordinates: event.coordinates,
        radiusInMetres: event.radiusInMetres
    ));
  }

  void _searchLocationsQuerySubmitted(SearchLocationsQuerySubmitted event, Emitter<SearchLocationsState> emit) async {
    final currentState = state;
    if (currentState is FetchLocationsAroundCoordinatesLoaded || currentState is SearchLocationsQueryModified) {
      emit(SearchLocationsResultsLoading(
          query: event.query,
          coordinates: event.coordinates,
          radiusInMetres: event.radiusInMetres
      ));
      try {
        final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
        Coordinates? coordinates;
        int? radiusInMetres;

        if (currentState is FetchLocationsAroundCoordinatesLoaded) {
          coordinates = currentState.coordinates;
          radiusInMetres = currentState.radiusInMetres;
        }
        else if (currentState is SearchLocationsQueryModified) {
          coordinates = currentState.coordinates;
          radiusInMetres = currentState.radiusInMetres;
        }

        final results = await meetupRepository
                          .getGymsAroundLocation(event.query, coordinates!, radiusInMetres!, accessToken!);
        emit(SearchLocationsResultsLoaded(
            query: event.query,
            locationResults: results,
            coordinates: event.coordinates,
            radiusInMetres: event.radiusInMetres
        ));
      } catch (ex) {
        emit(SearchLocationsResultsError(
            query: event.query,
            coordinates: event.coordinates,
            radiusInMetres: event.radiusInMetres,
            error: ex.toString()
        ));
      }
    }

  }
}