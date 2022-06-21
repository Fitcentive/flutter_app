import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/models/login/email_verification_token.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:formz/formz.dart';

abstract class CreateAccountState extends Equatable {
  const CreateAccountState();

  @override
  List<Object> get props => [];

}

class InitialState extends CreateAccountState {
  const InitialState();

  @override
  List<Object> get props => [];
}

class EmailAddressModified extends CreateAccountState {
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

class UnverifiedEmailAddress extends CreateAccountState {

  final String email;

  const UnverifiedEmailAddress(this.email);

  @override
  List<Object> get props => [email];

}

class VerificationTokenModified extends CreateAccountState {
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

class InvalidEmailVerificationToken extends CreateAccountState {

  final String email;
  final String invalidToken;

  const InvalidEmailVerificationToken(this.email, this.invalidToken);

  @override
  List<Object> get props => [email, invalidToken];

}

class VerifiedEmailAddress extends CreateAccountState {

  final String verificationToken;
  final String email;

  const VerifiedEmailAddress(this.email, this.verificationToken);

  @override
  List<Object> get props => [email, verificationToken];

}

class PasswordModified extends CreateAccountState {
  const PasswordModified({
    required this.email,
    required this.token,
    this.status = FormzStatus.pure,
    this.password = const Password.pure(),
    this.passwordConfirmation = const Password.pure(),
  });

  final FormzStatus status;
  final String email;
  final String token;
  final Password password;
  final Password passwordConfirmation;

  PasswordModified copyWith({
    FormzStatus? status,
    Password? password,
    Password? passwordConfirmation,
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

class AccountCreatedSuccessfully extends CreateAccountState {

  const AccountCreatedSuccessfully();

  @override
  List<Object> get props => [];
}