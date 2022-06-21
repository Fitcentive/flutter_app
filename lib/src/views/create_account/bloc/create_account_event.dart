import 'package:equatable/equatable.dart';

abstract class CreateAccountEvent extends Equatable {
  const CreateAccountEvent();

  @override
  List<Object> get props => [];
}

class InitiateCreateAccountFlow extends CreateAccountEvent {
  const InitiateCreateAccountFlow();

  @override
  List<Object> get props => [];
}

class EmailAddressChanged extends CreateAccountEvent {
  const EmailAddressChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class EmailAddressEnteredForVerification extends CreateAccountEvent {
  final String email;

  const EmailAddressEnteredForVerification(this.email);

  @override
  List<Object> get props => [email];
}

class EmailVerificationTokenChanged extends CreateAccountEvent {
  const EmailVerificationTokenChanged(this.email, this.token);

  final String email;
  final String token;

  @override
  List<Object> get props => [email, token];
}

class EmailVerificationTokenSubmitted extends CreateAccountEvent {
  final String email;
  final String verificationToken;

  const EmailVerificationTokenSubmitted(this.email, this.verificationToken);

  @override
  List<Object> get props => [email, verificationToken];
}

class PasswordChanged extends CreateAccountEvent {
  final String email;
  final String password;
  final String passwordConfirmation;

  const PasswordChanged(this.email, this.password, this.passwordConfirmation);

  @override
  List<Object> get props => [email, password, passwordConfirmation];
}

class PasswordSubmitted extends CreateAccountEvent {
  final String email;
  final String password;
  final String verificationToken;

  const PasswordSubmitted({required this.email, required this.password, required this.verificationToken});

  @override
  List<Object> get props => [email, password, verificationToken];
}

class TermsAndConditionsChanged extends CreateAccountEvent {
  final String email;
  final String password;
  final String verificationToken;
  final bool termsAndConditions;
  final bool marketingEmails;

  const TermsAndConditionsChanged(
      {required this.email,
      required this.password,
      required this.verificationToken,
      required this.termsAndConditions,
      required this.marketingEmails});

  @override
  List<Object> get props => [email, password, verificationToken, termsAndConditions, marketingEmails];
}

class CreateNewAccountRequested extends CreateAccountEvent {
  final String email;
  final String verificationToken;
  final String password;

  const CreateNewAccountRequested(this.email, this.verificationToken, this.password);

  @override
  List<Object> get props => [email, verificationToken, password];
}
