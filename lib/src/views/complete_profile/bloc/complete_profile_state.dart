import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/complete_profile/date_of_birth.dart';
import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:flutter_app/src/models/complete_profile/username.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:formz/formz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class CompleteProfileState extends Equatable {
  const CompleteProfileState();

  @override
  List<Object> get props => [];

}

class InitialState extends CompleteProfileState {
  const InitialState();

  @override
  List<Object> get props => [];

}

class CompleteProfileTermsAndConditionsModified extends CompleteProfileState {
  final AuthenticatedUser user;
  final bool termsAndConditions;
  final bool marketingEmails;

  const CompleteProfileTermsAndConditionsModified({
    required this.user,
    required this.termsAndConditions,
    required this.marketingEmails
  });

  bool isValidState() => termsAndConditions;

  CompleteProfileTermsAndConditionsModified copyWith({
    bool? termsAndConditions,
    bool? marketingEmails,
  }) {
    return CompleteProfileTermsAndConditionsModified(
      user: user,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }

  @override
  List<Object> get props => [termsAndConditions, marketingEmails];

}


class ProfileInfoModified extends CompleteProfileState {
  final AuthenticatedUser user;
  final FormzStatus status;
  final Name firstName;
  final Name lastName;
  final DateOfBirth dateOfBirth;

  const ProfileInfoModified({
    required this.user,
    this.status = FormzStatus.pure,
    this.firstName =  const Name.pure(),
    this.lastName = const Name.pure(),
    this.dateOfBirth = const DateOfBirth.pure(),
  });

  ProfileInfoModified copyWith({
    FormzStatus? status,
    Name? firstName,
    Name? lastName,
    DateOfBirth? dateOfBirth,
  }) {
    return ProfileInfoModified(
      user: user,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  @override
  List<Object> get props => [status, firstName, lastName, dateOfBirth];

}

class UsernameModified extends CompleteProfileState {
  final AuthenticatedUser user;
  final bool doesUsernameExistAlready;
  final Username username;
  final FormzStatus status;

  const UsernameModified({
    required this.user,
    this.doesUsernameExistAlready = true,
    this.status = FormzStatus.pure,
    this.username = const Username.pure(),
  });

  UsernameModified copyWith({
    FormzStatus? status,
    Username? username,
    bool? doesUsernameExistAlready,
  }) {
    return UsernameModified(
      user: user,
      doesUsernameExistAlready: doesUsernameExistAlready ?? this.doesUsernameExistAlready,
      status: status ?? this.status,
      username: username ?? this.username,
    );
  }

  @override
  List<Object> get props => [status, username];

}

class LocationInfoModified extends CompleteProfileState {
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

class ProfileInfoComplete extends CompleteProfileState {
  final AuthenticatedUser user;

  const ProfileInfoComplete(this.user);

  @override
  List<Object> get props => [user];

}



