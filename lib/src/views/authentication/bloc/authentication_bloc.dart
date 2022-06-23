import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/repos/authentication_repository.dart';
import 'package:flutter_app/src/repos/user_repository.dart';
import 'package:flutter_app/src/utils/jwt_utils.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';

import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;

  static const String GOOGLE_AUTH_PROVIDER = "GoogleAuth";
  static const String NATIVE_AUTH_PROVIDER = "NativeAuth";
  static const String GOOGLE_OIDC_REDIRECT_URI = 'io.fitcentive.fitcentive://oidc-callback';
  static const String GOOGLE_OIDC_DISCOVER_URI =
      'http://api.vid.app/auth/realms/GoogleAuth/.well-known/openid-configuration';
  static const String CLIENT_ID = 'webapp';

  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  AuthenticationBloc({required this.authenticationRepository, required this.userRepository})
      : super(AuthInitialState()) {
    // Event-Handler mappings
    on<SignInWithEmailEvent>(_signInWithEmail);
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<InitiateAuthenticationFlow>(_initiateAuthenticationFlow);
    on<SignInWithOidcEvent>(_signInWithOidc);
    on<SignOutEvent>(_signOut);
  }

  void _signInWithOidc(
    SignInWithOidcEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (event.provider == GOOGLE_AUTH_PROVIDER) {
      final authTokens = await _getGoogleOidcAuthTokens();
      final userId = JwtUtils.getUserIdFromJwtToken(authTokens.accessToken);
      final user = await userRepository.getUser(userId!, authTokens.accessToken);
      final authenticatedUser = AuthenticatedUser(user!, authTokens, event.provider);

      // todo - write to secure storage
      // todo - rename client, separate redirect URLs
      // todo - logout implementation
      emit(AuthSuccessState(authenticatedUser: authenticatedUser));
    }
  }

  // todo - need to handle null safety here
  Future<AuthTokens> _getGoogleOidcAuthTokens() async {
    final AuthorizationResponse? authorizationResponse = await appAuth.authorize(AuthorizationRequest(
        CLIENT_ID, GOOGLE_OIDC_REDIRECT_URI,
        discoveryUrl: GOOGLE_OIDC_DISCOVER_URI,
        scopes: ['openid', 'profile', 'email'],
        additionalParameters: {"kc_idp_hint": "google"}));

    final TokenResponse? result = await appAuth.token(TokenRequest(CLIENT_ID, GOOGLE_OIDC_REDIRECT_URI,
        authorizationCode: authorizationResponse!.authorizationCode,
        discoveryUrl: GOOGLE_OIDC_DISCOVER_URI,
        codeVerifier: authorizationResponse.codeVerifier,
        nonce: authorizationResponse.nonce,
        scopes: ['openid', 'profile', 'email']));

    return AuthTokens(
        result!.accessToken!,
        result.refreshToken!,
        result.accessTokenExpirationDateTime!.millisecondsSinceEpoch,
        result.accessTokenExpirationDateTime!.millisecondsSinceEpoch,
        result.tokenType!,
        result.scopes!.join(" "));
  }

  void _signOut(SignOutEvent event, Emitter<AuthenticationState> emit) async {
    if (event.user.authProvider == NATIVE_AUTH_PROVIDER) {
      await authenticationRepository.logout(
          accessToken: event.user.authTokens.accessToken, refreshToken: event.user.authTokens.refreshToken);
      emit(AuthInitialState());
    } else if (event.user.authProvider == GOOGLE_AUTH_PROVIDER) {
      print("NO IMPLEMENTATION YET, CAN TRY USING KEYCLOAK BASIC LOGOUT URL TO END SESSION");
    }
  }

  void _initiateAuthenticationFlow(
    InitiateAuthenticationFlow event,
    Emitter<AuthenticationState> emit,
  ) async {
    final username = event.username.isEmpty ? const Email.pure() : Email.dirty(event.username);
    final password = event.password.isEmpty ? const Password.pure() : Password.dirty(event.password);
    final status = Formz.validate([username, password]);
    emit(AuthCredentialsModified(status: status, username: username, password: password));
  }

  void _signInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      emit(const AuthLoadingState());
      final authTokens = await authenticationRepository.logIn(username: event.email, password: event.password);
      final userId = JwtUtils.getUserIdFromJwtToken(authTokens.accessToken);
      final user = await userRepository.getUser(userId!, authTokens.accessToken);
      final authenticatedUser = AuthenticatedUser(user!, authTokens, NATIVE_AUTH_PROVIDER);
      emit(AuthSuccessState(authenticatedUser: authenticatedUser));
    } catch (e) {
      emit(AuthFailureState());
    }
  }

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<AuthenticationState> emit,
  ) {
    final username = Email.dirty(event.username);
    final currentState = state;

    if (currentState is AuthCredentialsModified) {
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

    if (currentState is AuthCredentialsModified) {
      emit(currentState.copyWith(
        password: password,
        status: Formz.validate([password, currentState.username]),
      ));
    }
  }
}
