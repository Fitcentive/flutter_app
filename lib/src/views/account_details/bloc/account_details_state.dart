import 'package:equatable/equatable.dart';
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
  final FormzStatus status;
  final Name firstName;
  final Name lastName;
  final String? photoUrl;

  const AccountDetailsModified({
    required this.status,
    required this.firstName,
    required this.lastName,
    this.photoUrl
  });

  AccountDetailsModified copyWith({
    FormzStatus? status,
    Name? firstName,
    Name? lastName,
    String? photoUrl
  }) =>
      AccountDetailsModified(
          status: status ?? this.status,
          firstName: firstName ?? this.firstName,
          lastName: lastName ?? this.lastName,
          photoUrl: photoUrl ?? this.photoUrl
      );

  @override
  List<Object?> get props => [status, firstName, lastName, photoUrl];
}
