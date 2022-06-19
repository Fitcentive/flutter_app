import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/models/login/username.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/repos/authentication_repository.dart';
import 'package:flutter_app/src/repos/user_repository.dart';
import 'package:flutter_app/src/utils/jwt_utils.dart';
import 'package:formz/formz.dart';

import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;

  AuthenticationBloc({required this.authenticationRepository, required this.userRepository})
      : super(AuthInitialState()) {
    // Event-Handler mappings
    on<SignInWithEmailEvent>(_signInWithEmail);
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<InitiateAuthenticationFlow>(_initiateAuthenticationFlow);
    on<SignOutEvent>(_signOut);
  }

  void _signOut(SignOutEvent event, Emitter<AuthenticationState> emit) async {
    await authenticationRepository.logout(
        accessToken: event.user.authTokens.accessToken, refreshToken: event.user.authTokens.refreshToken);
    emit(AuthInitialState());
  }

  void _initiateAuthenticationFlow(
    InitiateAuthenticationFlow evebt,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthLoginState());
  }

  void _signInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    print("Handling signIn event");

    try {
      final authTokens = await authenticationRepository.logIn(username: event.email, password: event.password);

      print("Got auth tokens");

      print(authTokens);

      final userId = JwtUtils.getUserIdFromJwtToken(authTokens.accessToken);

      final user = await userRepository.getUser(userId!, authTokens.accessToken);

      print("Retrieved user info");
      print(user);

      final authenticatedUser = AuthenticatedUser(user!, authTokens);



      emit(AuthSuccessState(authenticatedUser: authenticatedUser));
    }
     catch (e) {
       emit(AuthFailureState());
     }
  }

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<AuthenticationState> emit,
  ) {
    final username = Username.dirty(event.username);
    final currentState = state;

    if (currentState is AuthLoginState) {
      emit(currentState.copyWith(
        username: username,
        status: Formz.validate([currentState.password, username]),
      ));
    }
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<AuthenticationState> emit,
  ) {
    final password = Password.dirty(event.password);
    final currentState = state;

    if (currentState is AuthLoginState) {
      emit(currentState.copyWith(
        password: password,
        status: Formz.validate([password, currentState.username]),
      ));
    }
  }
}
