import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DiscoveryRadiusState extends Equatable {
  const DiscoveryRadiusState();

  @override
  List<Object> get props => [];

}

class InitialState extends DiscoveryRadiusState {
  const InitialState();

  @override
  List<Object> get props => [];

}

class LocationBeingUpdated extends DiscoveryRadiusState {
  const LocationBeingUpdated();

  @override
  List<Object> get props => [];

}

class LocationInfoModified extends DiscoveryRadiusState {
  final AuthenticatedUser user;
  final LatLng selectedCoordinates;
  final int radius;

  const LocationInfoModified({
    required this.user,
    required this.selectedCoordinates,
    required this.radius,
  });

  @override
  List<Object> get props => [user, selectedCoordinates, radius];

}

class LocationInfoUpdated extends DiscoveryRadiusState {
  const LocationInfoUpdated();

  @override
  List<Object> get props => [];
}