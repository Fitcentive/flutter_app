import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/login/login_password.dart';
import 'package:flutter_app/src/models/login/new_password.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:formz/formz.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];

}

class AuthInitialState extends AuthenticationState {}

class AuthCredentialsModified extends AuthenticationState {
  const AuthCredentialsModified({
    this.status = FormzStatus.pure,
    this.email = const Email.pure(),
    this.password = const LoginPassword.pure(),
  });

  final FormzStatus status;
  final Email email;
  final LoginPassword password;

  AuthCredentialsModified copyWith({
    FormzStatus? status,
    Email? username,
    LoginPassword? password,
  }) {
    return AuthCredentialsModified(
      status: status ?? this.status,
      email: username ?? this.email,
      password: password ?? this.password,
    );
  }

  @override
  List<Object> get props => [status, email, password];
}

class AuthLoadingState extends AuthenticationState {

  const AuthLoadingState();

  @override
  List<Object> get props => [];
}

class AuthSuccessState extends AuthenticationState {
  final AuthenticatedUser authenticatedUser;

  const AuthSuccessState({required this.authenticatedUser});

  @override
  List<Object> get props => [authenticatedUser];
}

class AuthSuccessUserUpdateState extends AuthenticationState {
  final AuthenticatedUser authenticatedUser;

  const AuthSuccessUserUpdateState({required this.authenticatedUser});

  @override
  List<Object> get props => [authenticatedUser];
}

class UnauthorizedState extends AuthenticationState {}

class AuthFailureState extends AuthenticationState {}