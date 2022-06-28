import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class AccountDetailsEvent extends Equatable {
  const AccountDetailsEvent();
}

class AccountDetailsChanged extends AccountDetailsEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String? photoUrl;

  const AccountDetailsChanged({
    required this.user,
    required this.firstName,
    required this.lastName,
    this.photoUrl
  });

  @override
  List<Object?> get props => [user, firstName, lastName, photoUrl];
}

class AccountDetailsSaved extends AccountDetailsEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final String? photoUrl;

  const AccountDetailsSaved({
    required this.user,
    required this.firstName,
    required this.lastName,
    this.photoUrl
  });

  @override
  List<Object?> get props => [user, firstName, lastName, photoUrl];
}