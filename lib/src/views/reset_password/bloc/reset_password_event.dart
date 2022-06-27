import 'package:equatable/equatable.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object> get props => [];
}

class EmailAddressChanged extends ResetPasswordEvent {
  const EmailAddressChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class EmailAddressEnteredForVerification extends ResetPasswordEvent {
  final String email;

  const EmailAddressEnteredForVerification(this.email);

  @override
  List<Object> get props => [email];
}

class EmailVerificationTokenChanged extends ResetPasswordEvent {
  const EmailVerificationTokenChanged(this.email, this.token);

  final String email;
  final String token;

  @override
  List<Object> get props => [email, token];
}

class EmailVerificationTokenSubmitted extends ResetPasswordEvent {
  final String email;
  final String verificationToken;

  const EmailVerificationTokenSubmitted(this.email, this.verificationToken);

  @override
  List<Object> get props => [email, verificationToken];
}

class PasswordChanged extends ResetPasswordEvent {
  final String email;
  final String password;
  final String passwordConfirmation;

  const PasswordChanged(this.email, this.password, this.passwordConfirmation);

  @override
  List<Object> get props => [email, password, passwordConfirmation];
}

class PasswordSubmitted extends ResetPasswordEvent {
  final String email;
  final String password;
  final String verificationToken;

  const PasswordSubmitted({required this.email, required this.password, required this.verificationToken});

  @override
  List<Object> get props => [email, password, verificationToken];
}