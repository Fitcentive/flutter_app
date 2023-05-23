import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/models/login/email_verification_token.dart';
import 'package:flutter_app/src/models/login/new_password.dart';
import 'package:formz/formz.dart';

abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();

  @override
  List<Object> get props => [];

}

class InitialState extends ResetPasswordState {
  const InitialState();

  @override
  List<Object> get props => [];
}

class EmailAddressModified extends ResetPasswordState {
  const EmailAddressModified({
    this.status = FormzStatus.pure,
    this.email = const Email.pure(),
  });

  final FormzStatus status;
  final Email email;

  EmailAddressModified copyWith({
    FormzStatus? status,
    Email? email,
  }) {
    return EmailAddressModified(
        status: status ?? this.status,
        email: email ?? this.email
    );
  }

  @override
  List<Object> get props => [status, email];
}

class UnrecognizedEmailAddress extends ResetPasswordState {

  final String email;

  const UnrecognizedEmailAddress(this.email);

  @override
  List<Object> get props => [email];

}

class VerificationTokenModified extends ResetPasswordState {
  const VerificationTokenModified({
    required this.email,
    this.status = FormzStatus.pure,
    this.token = const EmailVerificationToken.pure(),
  });

  final FormzStatus status;
  final String email;
  final EmailVerificationToken token;

  VerificationTokenModified copyWith({
    FormzStatus? status,
    EmailVerificationToken? token,
  }) {
    return VerificationTokenModified(
        email: email,
        status: status ?? this.status,
        token: token ?? this.token
    );
  }

  @override
  List<Object> get props => [status, email, token];
}

class InvalidEmailVerificationToken extends ResetPasswordState {

  final String email;
  final String invalidToken;

  const InvalidEmailVerificationToken(this.email, this.invalidToken);

  @override
  List<Object> get props => [email, invalidToken];

}

class PasswordModified extends ResetPasswordState {
  const PasswordModified({
    required this.email,
    required this.token,
    this.status = FormzStatus.pure,
    this.password = const NewPassword.pure(),
    this.passwordConfirmation = const NewPassword.pure(),
  });

  final FormzStatus status;
  final String email;
  final String token;
  final NewPassword password;
  final NewPassword passwordConfirmation;

  bool doPasswordMatch() => password == passwordConfirmation;

  PasswordModified copyWith({
    FormzStatus? status,
    NewPassword? password,
    NewPassword? passwordConfirmation,
  }) {
    return PasswordModified(
        email: email,
        token: token,
        status: status ?? this.status,
        password: password ?? this.password,
        passwordConfirmation: passwordConfirmation ?? this.passwordConfirmation
    );
  }

  @override
  List<Object> get props => [status, email, password, passwordConfirmation];
}

class PasswordResetSuccessfully extends ResetPasswordState {
  final String email;
  final String password;

  const PasswordResetSuccessfully({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}