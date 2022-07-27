import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class AccountDetailsEvent extends Equatable {
  const AccountDetailsEvent();
}

class AccountDetailsChanged extends AccountDetailsEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String gender;
  final String? photoUrl;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const AccountDetailsChanged({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.photoUrl,
    this.selectedImage,
    this.selectedImageName
  });

  @override
  List<Object?> get props => [user, firstName, lastName, gender, photoUrl, selectedImage, selectedImageName];
}

class AccountDetailsSaved extends AccountDetailsEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String gender;
  final String? photoUrl;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const AccountDetailsSaved({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.photoUrl,
    this.selectedImage,
    this.selectedImageName
  });

  @override
  List<Object?> get props => [user, firstName, lastName, gender, photoUrl, selectedImage, selectedImageName];
}