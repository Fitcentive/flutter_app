import 'package:equatable/equatable.dart';

abstract class CreateAccountEvent extends Equatable {
  const CreateAccountEvent();

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
  final bool privacyPolicy;

  const TermsAndConditionsChanged({
    required this.email,
    required this.password,
    required this.verificationToken,
    required this.termsAndConditions,
    required this.marketingEmails,
    required this.privacyPolicy,
  });

  @override
  List<Object> get props => [email, password, verificationToken, termsAndConditions, marketingEmails, privacyPolicy];
}

class CreateNewAccountRequested extends CreateAccountEvent {
  final String email;
  final String verificationToken;
  final String password;
  final bool termsAndConditions;
  final bool marketingEmails;
  final bool privacyPolicy;

  const CreateNewAccountRequested({
    required this.email,
    required this.verificationToken,
    required this.password,
    required this.termsAndConditions,
    required this.marketingEmails,
    required this.privacyPolicy,
  });

  @override
  List<Object> get props => [email, verificationToken, password, termsAndConditions, marketingEmails, privacyPolicy];
}
