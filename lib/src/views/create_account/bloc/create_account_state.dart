import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/models/login/email_verification_token.dart';
import 'package:flutter_app/src/models/login/new_password.dart';
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

class AccountBeingCreated extends CreateAccountState {
  const AccountBeingCreated();

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

class EmailAddressAlreadyInUse extends CreateAccountState {

  final String email;

  const EmailAddressAlreadyInUse(this.email);

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

class PasswordModified extends CreateAccountState {
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

class TermsAndConditionsModified extends CreateAccountState {
  final String email;
  final String password;
  final String verificationToken;
  final bool termsAndConditions;
  final bool marketingEmails;
  final bool privacyPolicy;

  const TermsAndConditionsModified({
    required this.email,
    required this.password,
    required this.verificationToken,
    required this.termsAndConditions,
    required this.marketingEmails,
    required this.privacyPolicy
  });

  bool isValidState() => termsAndConditions && privacyPolicy;

  TermsAndConditionsModified copyWith({
    bool? termsAndConditions,
    bool? marketingEmails,
    bool? privacyPolicy,
  }) {
    return TermsAndConditionsModified(
        email: email,
        password: password,
        verificationToken: verificationToken,
        termsAndConditions: termsAndConditions ?? this.termsAndConditions,
        marketingEmails: marketingEmails ?? this.marketingEmails,
        privacyPolicy: privacyPolicy ?? this.privacyPolicy,
    );
  }

  @override
  List<Object> get props => [email, password, verificationToken, termsAndConditions, marketingEmails, privacyPolicy];

}

class AccountCreatedSuccessfully extends CreateAccountState {
  final String email;
  final String password;

  const AccountCreatedSuccessfully({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}