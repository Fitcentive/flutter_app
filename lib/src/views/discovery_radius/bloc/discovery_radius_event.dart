import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DiscoveryRadiusEvent extends Equatable {
  const DiscoveryRadiusEvent();

  @override
  List<Object> get props => [];
}

class LocationInfoChanged extends DiscoveryRadiusEvent {
  final AuthenticatedUser user;
  final LatLng coordinates;
  final int radius;

  const LocationInfoChanged({
    required this.user,
    required this.coordinates,
    required this.radius,
  });

  @override
  List<Object> get props => [user, coordinates, radius];
}

class LocationInfoSubmitted extends DiscoveryRadiusEvent {
  final AuthenticatedUser user;
  final LatLng coordinates;
  final int radius;

  const LocationInfoSubmitted({
    required this.user,
    required this.coordinates,
    required this.radius,
  });

  @override
  List<Object> get props => [user, coordinates, radius];
}