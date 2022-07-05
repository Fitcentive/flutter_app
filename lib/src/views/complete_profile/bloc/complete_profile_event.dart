import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

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
  final DateTime dateOfBirth;

  const ProfileInfoChanged({required this.user, required this.firstName, required this.lastName, required this.dateOfBirth});

  @override
  List<Object> get props => [user, firstName, lastName, dateOfBirth];
}

class ProfileInfoSubmitted extends CompleteProfileEvent {
  final AuthenticatedUser user;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;

  const ProfileInfoSubmitted({required this.user, required this.firstName, required this.lastName, required this.dateOfBirth});

  @override
  List<Object> get props => [user, firstName, lastName, dateOfBirth];
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

class ForceUpdateAuthState extends CompleteProfileEvent {
  final AuthenticatedUser user;

  const ForceUpdateAuthState(this.user);

  @override
  List<Object> get props => [user];

}
