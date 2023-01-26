import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';

abstract class SearchLocationsState extends Equatable {
  const SearchLocationsState();

  @override
  List<Object?> get props => [];
}

class SearchLocationsStateInitial extends SearchLocationsState {

  const SearchLocationsStateInitial();

  @override
  List<Object> get props => [];
}

class FetchLocationsAroundCoordinatesLoading extends SearchLocationsState {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;

  const FetchLocationsAroundCoordinatesLoading({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres
  });

  @override
  List<Object> get props => [query, coordinates, radiusInMetres];
}

class FetchLocationsAroundCoordinatesLoaded extends SearchLocationsState {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;
  final List<Location> locationResults;

  const FetchLocationsAroundCoordinatesLoaded({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres,
    required this.locationResults,
  });

  @override
  List<Object> get props => [query, coordinates, locationResults, radiusInMetres];
}

class FetchLocationsAroundCoordinatesError extends SearchLocationsState {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;
  final String error;

  const FetchLocationsAroundCoordinatesError({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres,
    required this.error,
  });

  @override
  List<Object> get props => [query, coordinates, radiusInMetres, error];
}
