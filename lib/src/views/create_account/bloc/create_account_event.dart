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

class PasswordResetRequested extends CreateAccountEvent {

  final String email;
  final String verificationToken;
  final String password;
  final String passwordConfirmation;

  const PasswordResetRequested(this.email, this.verificationToken, this.password, this.passwordConfirmation);

  @override
  List<Object> get props => [email, verificationToken, password, passwordConfirmation];
}

