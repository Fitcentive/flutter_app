import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class InitiateAuthenticationFlow extends AuthenticationEvent {

  final String username;
  final String password;

  const InitiateAuthenticationFlow({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class LoginUsernameChanged extends AuthenticationEvent {
  const LoginUsernameChanged(this.username);

  final String username;

  @override
  List<Object> get props => [username];
}

class LoginPasswordChanged extends AuthenticationEvent {
  const LoginPasswordChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}


class SignInWithEmailEvent extends AuthenticationEvent {

  final String email;
  final String password;

  const SignInWithEmailEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignInWithOidcEvent extends AuthenticationEvent {

  final String provider;

  const SignInWithOidcEvent({required this.provider});

  @override
  List<Object> get props => [provider];
}

class RefreshAccessTokenRequested extends AuthenticationEvent {

  final AuthenticatedUser user;

  const RefreshAccessTokenRequested({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthenticatedUserDataUpdated extends AuthenticationEvent {

  final AuthenticatedUser user;

  const AuthenticatedUserDataUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

class RestoreAuthSuccessState extends AuthenticationEvent {
  final AuthTokens tokens;
  final AuthenticatedUser user;

  const RestoreAuthSuccessState({required this.user, required this.tokens});

  @override
  List<Object> get props => [user];
}

class SignOutEvent extends AuthenticationEvent {

  final AuthenticatedUser user;

  const SignOutEvent({required this.user});

  @override
  List<Object> get props => [user];
}
