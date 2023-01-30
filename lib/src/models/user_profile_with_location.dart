import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

class UserProfileWithLocation extends Equatable {
  final PublicUserProfile currentUserProfile;
  final double latitude;
  final double longitude;
  final double radiusInMetres;

  const UserProfileWithLocation(
      this.currentUserProfile,
      this.latitude,
      this.longitude,
      this.radiusInMetres
  );

  @override
  List<Object> get props => [
    currentUserProfile,
    latitude,
    longitude,
    radiusInMetres,
  ];
}
