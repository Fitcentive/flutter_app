import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:image_picker/image_picker.dart';

abstract class AccountDetailsEvent extends Equatable {
  const AccountDetailsEvent();
}

class AccountDetailsChanged extends AccountDetailsEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final XFile? selectedImage;

  const AccountDetailsChanged({
    required this.user,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.selectedImage
  });

  @override
  List<Object?> get props => [user, firstName, lastName, photoUrl, selectedImage];
}

class AccountDetailsSaved extends AccountDetailsEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final XFile? selectedImage;

  const AccountDetailsSaved({
    required this.user,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.selectedImage
  });

  @override
  List<Object?> get props => [user, firstName, lastName, photoUrl, selectedImage];
}