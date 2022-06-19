import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/models/login/username.dart';
import 'package:formz/formz.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];

}

class AuthLoginState extends AuthenticationState {
  const AuthLoginState({
    this.status = FormzStatus.pure,
    this.username = const Username.pure(),
    this.password = const Password.pure(),
  });

  final FormzStatus status;
  final Username username;
  final Password password;

  AuthLoginState copyWith({
    FormzStatus? status,
    Username? username,
    Password? password,
  }) {
    return AuthLoginState(
      status: status ?? this.status,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  List<Object> get props => [status, username, password];
}



class AuthLoadingState extends AuthenticationState {
  final bool isLoading;

  const AuthLoadingState({
    this.isLoading = false,
  });

  AuthLoadingState copyWith({bool? isLoading}) {
    return AuthLoadingState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [isLoading];
}

class AuthSuccessState extends AuthenticationState {
  final AuthenticatedUser authenticatedUser;

  const AuthSuccessState({required this.authenticatedUser});

  @override
  List<Object> get props => [authenticatedUser];
}

class AuthInitialState extends AuthenticationState {}

class UnauthorizedState extends AuthenticationState {}

class AuthFailureState extends AuthenticationState {}