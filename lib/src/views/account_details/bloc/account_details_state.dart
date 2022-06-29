import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:formz/formz.dart';
import 'package:image_picker/image_picker.dart';

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
  final String? photoUrl;
  final XFile? selectedImage;

  const AccountDetailsModified({
    required this.user,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.selectedImage,
  });

  AccountDetailsModified copyWith({
    FormzStatus? status,
    Name? firstName,
    Name? lastName,
    required String? photoUrl,
    required XFile? selectedImage,
  }) =>
      AccountDetailsModified(
          user: user,
          status: status ?? this.status,
          firstName: firstName ?? this.firstName,
          lastName: lastName ?? this.lastName,
          photoUrl: photoUrl,
          selectedImage: selectedImage,
      );

  @override
  List<Object?> get props => [status, firstName, lastName, photoUrl, user, selectedImage];
}

class AccountDetailsUpdatedSuccessfully extends AccountDetailsState {
  final AuthenticatedUser user;
  final FormzStatus status;
  final Name firstName;
  final Name lastName;
  final String? photoUrl;
  final XFile? selectedImage;

  const AccountDetailsUpdatedSuccessfully({
    required this.user,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.selectedImage,
  });

  @override
  List<Object?> get props => [status, firstName, lastName, photoUrl, user, selectedImage];
}