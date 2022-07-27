import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:formz/formz.dart';

abstract class AccountDetailsState extends Equatable {
  const AccountDetailsState();

  @override
  List<Object?> get props => [];

}

class InitialState extends AccountDetailsState {
  const InitialState();

  @override
  List<Object?> get props => [];

}

class AccountDetailsModified extends AccountDetailsState {
  final AuthenticatedUser user;
  final FormzStatus status;
  final Name firstName;
  final Name lastName;
  final String gender;
  final String? photoUrl;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const AccountDetailsModified({
    required this.user,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.photoUrl,
    this.selectedImage,
    this.selectedImageName
  });

  AccountDetailsModified copyWith({
    FormzStatus? status,
    Name? firstName,
    Name? lastName,
    String? gender,
    required String? photoUrl,
    required Uint8List? selectedImage,
    required String? selectedImageName,
  }) =>
      AccountDetailsModified(
          user: user,
          status: status ?? this.status,
          firstName: firstName ?? this.firstName,
          lastName: lastName ?? this.lastName,
          gender: gender ?? this.gender,
          photoUrl: photoUrl,
          selectedImage: selectedImage,
          selectedImageName: selectedImageName,
      );

  @override
  List<Object?> get props => [status, firstName, lastName, photoUrl, user, selectedImage, gender, selectedImageName];
}

class AccountDetailsUpdatedSuccessfully extends AccountDetailsState {
  final AuthenticatedUser user;
  final FormzStatus status;
  final Name firstName;
  final Name lastName;
  final String gender;
  final String? photoUrl;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const AccountDetailsUpdatedSuccessfully({
    required this.user,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.photoUrl,
    this.selectedImage,
    this.selectedImageName,
  });

  @override
  List<Object?> get props => [status, firstName, lastName, photoUrl, user, selectedImage, gender, selectedImageName];
}