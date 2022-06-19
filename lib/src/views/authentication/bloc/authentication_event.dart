import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class InitiateAuthenticationFlow extends AuthenticationEvent {}

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

class SignOutEvent extends AuthenticationEvent {

  final AuthenticatedUser user;

  const SignOutEvent({required this.user});

  @override
  List<Object> get props => [user];
}
