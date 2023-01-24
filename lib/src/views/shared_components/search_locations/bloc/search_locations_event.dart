import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';

abstract class SearchLocationsEvent extends Equatable {
  const SearchLocationsEvent();
}

class FetchLocationsAroundCoordinatesRequested extends SearchLocationsEvent {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;

  const FetchLocationsAroundCoordinatesRequested({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres
  });

  @override
  List<Object?> get props => [query, coordinates, radiusInMetres];
}


class SearchLocationsQueryChanged extends SearchLocationsEvent {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;

  const SearchLocationsQueryChanged({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres
  });

  @override
  List<Object?> get props => [query, coordinates, radiusInMetres];
}

class SearchLocationsQuerySubmitted extends SearchLocationsEvent {
  final String query;
  final Coordinates coordinates;
  final int radiusInMetres;

  const SearchLocationsQuerySubmitted({
    required this.query,
    required this.coordinates,
    required this.radiusInMetres
  });

  @override
  List<Object?> get props => [query, coordinates, radiusInMetres];
}

class SearchLocationsQueryReset extends SearchLocationsEvent {
  final Coordinates coordinates;
  final int radiusInMetres;

  const SearchLocationsQueryReset({
    required this.coordinates,
    required this.radiusInMetres
  });

  @override
  List<Object?> get props => [coordinates, radiusInMetres];
}