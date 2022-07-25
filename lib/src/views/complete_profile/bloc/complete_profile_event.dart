import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();

  @override
  List<Object> get props => [];
}

class InitialEvent extends CompleteProfileEvent {
  final AuthenticatedUser user;

  const InitialEvent({required this.user});

  @override
  List<Object> get props => [user];
}

class CompleteProfileTermsAndConditionsChanged extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final bool termsAndConditions;
  final bool marketingEmails;

  const CompleteProfileTermsAndConditionsChanged(
      {required this.user, required this.termsAndConditions, required this.marketingEmails});

  @override
  List<Object> get props => [user, termsAndConditions, marketingEmails];
}

class CompleteProfileTermsAndConditionsSubmitted extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final bool termsAndConditions;
  final bool marketingEmails;

  const CompleteProfileTermsAndConditionsSubmitted(
      {required this.user, required this.termsAndConditions, required this.marketingEmails});

  @override
  List<Object> get props => [user, termsAndConditions, marketingEmails];
}

class ProfileInfoChanged extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime dateOfBirth;

  const ProfileInfoChanged({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth
  });

  @override
  List<Object> get props => [user, firstName, lastName, dateOfBirth, gender];
}

class ProfileInfoSubmitted extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime dateOfBirth;

  const ProfileInfoSubmitted({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth
  });

  @override
  List<Object> get props => [user, firstName, lastName, gender, dateOfBirth];
}

class UsernameChanged extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final String username;

  const UsernameChanged({required this.user, required this.username});

  @override
  List<Object> get props => [user, username];
}

class UsernameSubmitted extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final String username;

  const UsernameSubmitted({required this.user, required this.username});

  @override
  List<Object> get props => [user, username];
}

class LocationInfoChanged extends CompleteProfileEvent {
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

class LocationInfoSubmitted extends CompleteProfileEvent {
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

class ForceUpdateAuthState extends CompleteProfileEvent {
  final AuthenticatedUser user;

  const ForceUpdateAuthState(this.user);

  @override
  List<Object> get props => [user];

}
