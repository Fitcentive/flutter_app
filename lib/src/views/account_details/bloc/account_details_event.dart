import 'package:equatable/equatable.dart';

abstract class AccountDetailsEvent extends Equatable {
  const AccountDetailsEvent();
}

class AccountDetailsChanged extends AccountDetailsEvent {
  final String firstName;
  final String lastName;
  final String? photoUrl;

  const AccountDetailsChanged({required this.firstName, required this.lastName, this.photoUrl});

  @override
  List<Object?> get props => [firstName, lastName, photoUrl];
}

class AccountDetailsSaved extends AccountDetailsEvent {
  final String firstName;
  final String lastName;
  final String? photoUrl;

  const AccountDetailsSaved({required this.firstName, required this.lastName, this.photoUrl});

  @override
  List<Object?> get props => [firstName, lastName, photoUrl];
}