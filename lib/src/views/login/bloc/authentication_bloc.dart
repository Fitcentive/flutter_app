import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/models/auth/oidc_provider_info.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/repos/rest/authentication_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/utils/jwt_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';

import 'authentication_event.dart';

// todo - strategy for handling exceptions thrown
// todo - increase access token expiration duration in keycloak
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;
  final AuthenticatedUserStreamRepository authUserStreamRepository;

  late final StreamSubscription<AuthenticatedUser>_authenticatedUserSubscription;

  AuthenticationBloc({
    required this.authenticationRepository,
    required this.userRepository,
    required this.secureStorage,
    required this.authUserStreamRepository
  }) : super(AuthInitialState()) {
    // Event-Handler mappings
    on<SignInWithEmailEvent>(_signInWithEmail);
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<InitiateAuthenticationFlow>(_initiateAuthenticationFlow);
    on<SignInWithOidcEvent>(_signInWithOidc);
    on<SignOutEvent>(_signOut);
    on<AuthenticatedUserDataUpdated>(_authenticatedUserDataUpdated);
    on<RefreshAccessTokenRequested>(_refreshAccessTokenRequested);

    _authenticatedUserSubscription = authUserStreamRepository.authenticatedUser.listen((newUser) {
      add(AuthenticatedUserDataUpdated(user: newUser));
    });
  }

  void _refreshAccessTokenRequested(
      RefreshAccessTokenRequested event,
      Emitter<AuthenticationState> emit
      ) async {
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final refreshToken = await secureStorage.read(key: event.user.authTokens.refreshTokenSecureStorageKey);
    if (accessToken != null && refreshToken != null) {
      final newAuthTokens = await authenticationRepository.refreshAccessToken(
          accessToken: accessToken,
          refreshToken: refreshToken,
          providerRealm: event.user.user.authProvider
      );
      final newAuthenticatedUser = AuthenticatedUser(
          user: event.user.user,
          userProfile: event.user.userProfile,
          userAgreements: event.user.userAgreements,
          authTokens: SecureAuthTokens.fromAuthTokens(newAuthTokens),
          authProvider: event.user.user.authProvider
      );

      _setUpRefreshAccessTokenTrigger(newAuthTokens, newAuthenticatedUser);
      emit(AuthSuccessUserUpdateState(authenticatedUser: newAuthenticatedUser));
    }
  }

  void _authenticatedUserDataUpdated(
      AuthenticatedUserDataUpdated event,
      Emitter<AuthenticationState> emit) async {
    emit(AuthSuccessUserUpdateState(authenticatedUser: event.user));
  }

  void _signInWithEmail(
      SignInWithEmailEvent event,
      Emitter<AuthenticationState> emit,) async {
    try {
      emit(const AuthLoadingState());
      final authTokens = await authenticationRepository.basicLogIn(username: event.email, password: event.password);
      final authenticatedUser =
        await _storeTokensAndGetAuthenticatedUser(authTokens, OidcProviderInfo.NATIVE_AUTH_PROVIDER);
      _setUpRefreshAccessTokenTrigger(authTokens, authenticatedUser);
      emit(AuthSuccessState(authenticatedUser: authenticatedUser));
    } catch (e) {
      emit(AuthFailureState());
    }
  }

  void _signInWithOidc(SignInWithOidcEvent event,
      Emitter<AuthenticationState> emit,) async {
    final authTokens = await authenticationRepository.oidcLogin(providerRealm: event.provider);
    final authenticatedUser = await _storeTokensAndGetAuthenticatedUser(authTokens, event.provider);
    _setUpRefreshAccessTokenTrigger(authTokens, authenticatedUser);
    emit(AuthSuccessState(authenticatedUser: authenticatedUser));
  }

  void _setUpRefreshAccessTokenTrigger(AuthTokens authTokens, AuthenticatedUser user) =>
      // Refresh auth token 5 minute before expiry
      Future.delayed(Duration(seconds: authTokens.expiresIn - 60), () {
        add(RefreshAccessTokenRequested(user: user));
      });

  Future<AuthenticatedUser> _storeTokensAndGetAuthenticatedUser(AuthTokens authTokens, String authRealm) async {
    await secureStorage.write(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY, value: authTokens.accessToken);
    await secureStorage.write(key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY, value: authTokens.refreshToken);
    final userId = JwtUtils.getUserIdFromJwtToken(authTokens.accessToken);
    if (userId == null) {
      // This is the case when a new user logins with SSO for the first time, and there is no user ID yet
      await authenticationRepository.createNewSsoUser(authRealm, authTokens.accessToken);
      final freshTokens = await authenticationRepository.refreshNewSsoUserAccessToken(
          accessToken: authTokens.accessToken,
          refreshToken: authTokens.refreshToken,
          providerRealm: authRealm
      );
      await secureStorage.write(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY, value: freshTokens.accessToken);
      await secureStorage.write(
          key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY, value: freshTokens.refreshToken);
      final freshUserId = JwtUtils.getUserIdFromJwtToken(freshTokens.accessToken);
      final user = await userRepository.getUser(freshUserId!, freshTokens.accessToken);
      final userProfile = await userRepository.getUserProfile(freshUserId, freshTokens.accessToken);
      final userAgreements = await userRepository.getUserAgreements(freshUserId, freshTokens.accessToken);
      return AuthenticatedUser(
          user: user!,
          userProfile: userProfile,
          userAgreements: userAgreements,
          authTokens: SecureAuthTokens.fromAuthTokens(freshTokens),
          authProvider: authRealm
      );
    }
    else {
      final user = await userRepository.getUser(userId, authTokens.accessToken);
      final userProfile = await userRepository.getUserProfile(userId, authTokens.accessToken);
      final userAgreements = await userRepository.getUserAgreements(userId, authTokens.accessToken);
      return AuthenticatedUser(
          user: user!,
          userProfile: userProfile,
          userAgreements: userAgreements,
          authTokens: SecureAuthTokens.fromAuthTokens(authTokens),
          authProvider: authRealm
      );
    }
  }

  void _signOut(SignOutEvent event, Emitter<AuthenticationState> emit) async {
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final refreshToken = await secureStorage.read(key: event.user.authTokens.refreshTokenSecureStorageKey);
    await authenticationRepository.logout(
      accessToken: accessToken!,
      refreshToken: refreshToken!,
      authRealm: event.user.authProvider,
    );
    await secureStorage.delete(key: event.user.authTokens.accessTokenSecureStorageKey);
    await secureStorage.delete(key: event.user.authTokens.refreshTokenSecureStorageKey);
    emit(AuthInitialState());
  }

  void _initiateAuthenticationFlow(InitiateAuthenticationFlow event,
      Emitter<AuthenticationState> emit,) async {
    final username = event.username.isEmpty ? const Email.pure() : Email.dirty(event.username);
    final password = event.password.isEmpty ? const Password.pure() : Password.dirty(event.password);
    final status = Formz.validate([username, password]);
    emit(AuthCredentialsModified(status: status, username: username, password: password));
  }

  void _onUsernameChanged(LoginUsernameChanged event,
      Emitter<AuthenticationState> emit,) {
    final username = Email.dirty(event.username);
    final currentState = state;

    if (currentState is AuthCredentialsModified) {
      emit(currentState.copyWith(
        username: username,
        status: Formz.validate([currentState.password, username]),
      ));
    }
  }

  void _onPasswordChanged(LoginPasswordChanged event,
      Emitter<AuthenticationState> emit,) {
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
