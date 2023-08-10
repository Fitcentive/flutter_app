import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
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
    on<FetchLocationsAroundCoordinatesRequested>(_fetchLocationsAroundCoordinatesRequested);
    on<FetchLocationsByFsqId>(_fetchLocationsByFsqId);
  }

  void _fetchLocationsByFsqId(
      FetchLocationsByFsqId event,
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
      final result = await meetupRepository.getLocationByFsqId(event.fsqId, accessToken!);
      emit(
          FetchLocationsAroundCoordinatesLoaded(
              query: event.query,
              locationResults: [...event.previousLocationResults, result],
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

}