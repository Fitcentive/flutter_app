import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';

abstract class SearchLocationsEvent extends Equatable {
  const SearchLocationsEvent();
}

class FetchLocationsAroundCoordinatesRequested extends SearchLocationsEvent {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;
  final List<Location> previousLocationResults;

  const FetchLocationsAroundCoordinatesRequested({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres,
    required this.previousLocationResults,
  });

  @override
  List<Object?> get props => [query, coordinates, radiusInMetres, previousLocationResults];
}

class FetchLocationsByFsqId extends SearchLocationsEvent {
  final String fsqId;
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;
  final List<Location> previousLocationResults;

  const FetchLocationsByFsqId({
    required this.fsqId,
    required this.query,
    required this.coordinates,
    required this.radiusInMetres,
    required this.previousLocationResults,
  });

  @override
  List<Object?> get props => [fsqId, query, coordinates, radiusInMetres, previousLocationResults];
}