import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/firebase/firebase_options.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/step_count_stream_repository.dart';
import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/models/auth/oidc_provider_info.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/diary/user_steps_data.dart';
import 'package:flutter_app/src/models/login/login_password.dart';
import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/authentication_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/authenticated_user_stream_repository.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/jwt_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'authentication_event.dart';

// Note - refresh token gets updated along with access token, user never forced to logout
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository authenticationRepository;
  final NotificationRepository notificationRepository;
  final UserRepository userRepository;
  final ChatRepository chatRepository;
  final DiaryRepository diaryRepository;
  final FlutterSecureStorage secureStorage;
  final AuthenticatedUserStreamRepository authUserStreamRepository;

  Timer? _refreshAccessTokenTimer;
  Timer? _syncStepsDataTimer;

  late final StreamSubscription<AuthenticatedUser>_authenticatedUserSubscription;
  late final Stream<StepCount> _stepCountStream;

  final StepCountStreamRepository stepCountStreamRepository;

  final logger = Logger("AuthenticationBloc");

  bool isFirstTimeSync = true;
  int pedometerStepCount = 0;

  final BuildContext context;

  AuthenticationBloc({
    required this.authenticationRepository,
    required this.notificationRepository,
    required this.userRepository,
    required this.chatRepository,
    required this.diaryRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
    required this.stepCountStreamRepository,
    required this.context,
  }) : super(AuthInitialState()) {
    on<SignInWithEmailEvent>(_signInWithEmail);
    on<LoginEmailChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<InitiateAuthenticationFlow>(_initiateAuthenticationFlow);
    on<SignInWithOidcEvent>(_signInWithOidc);
    on<SignOutEvent>(_signOut);
    on<AuthenticatedUserDataUpdated>(_authenticatedUserDataUpdated);
    on<RefreshAccessTokenRequested>(_refreshAccessTokenRequested);
    on<RestoreAuthSuccessState>(_restoreAuthSuccessState);
    on<AccountDeletionRequested>(_accountDeletionRequested);
    on<SyncStepsDataRequested>(_syncStepsDataRequested);
    on<SetupPedometerAgain>(_setupPedometerAgain);

    _authenticatedUserSubscription = authUserStreamRepository.authenticatedUser.listen((newUser) {
      add(AuthenticatedUserDataUpdated(user: newUser));
    });

    if (DeviceUtils.isMobileDevice()) {
      _stepCountStream = Pedometer.stepCountStream;
    }
    _setupPedometer();
  }

  void _setupPedometer() async {
    if (DeviceUtils.isMobileDevice()) {
      // _stepCountStream = Pedometer.stepCountStream;
      if (DeviceUtils.isAndroid()) {
        if(await Permission.activityRecognition.request().isGranted) {
          _stepCountStream.listen(onStepCount);
        }
        else {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.activityRecognition,
          ].request();

          if (statuses[Permission.activityRecognition] == PermissionStatus.granted) {
            _stepCountStream.listen(onStepCount);
          }
        }
      }
      else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.sensors,
        ].request();

        if (statuses[Permission.sensors] == PermissionStatus.granted) {
          _stepCountStream.listen(onStepCount);
        }
      }
    }
  }


  void onStepCount(StepCount event) {
    pedometerStepCount = event.steps;
    stepCountStreamRepository.newStepCount(event.steps);
  }

  void _setupPedometerAgain(SetupPedometerAgain event, Emitter<AuthenticationState> emit) async {
    _setupPedometer();
  }


  void _syncStepsDataRequested(SyncStepsDataRequested event, Emitter<AuthenticationState> emit) async {
    if (DeviceUtils.isMobileDevice()) {
      final bool isReadyToSync;
      if (DeviceUtils.isAndroid()) {
        isReadyToSync = await Permission.activityRecognition.request().isGranted;
      }
      else {
        isReadyToSync = await Permission.sensors.request().isGranted;
      }

      if (isReadyToSync) {
        _stepCountStream.listen(onStepCount); // If permissions were granted in background, this will catch it
        final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
        final fitnessUserProfile = await diaryRepository.getFitnessUserProfile(event.user.user.id, accessToken!);
        if (fitnessUserProfile != null) {
          diaryRepository.upsertUserStepsData(
              event.user.user.id,
              UserStepsDataUpsert(
                  stepsTaken: pedometerStepCount,
                  dateString: DateFormat('yyyy-MM-dd').format(DateTime.now())
              ),
              accessToken
          );
          _setUpSyncStepsDataRequestedTrigger(event.user);
        }
      }
    }
  }

  void _accountDeletionRequested(AccountDeletionRequested event, Emitter<AuthenticationState> emit) async {
    emit(const AccountDeletionInProgressState());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.deleteUserData(event.user.user.id, accessToken!);
    _signOutWorkflow(event.user.user.id, event.user.authProvider);
    emit(AuthInitialState());
  }

  void _restoreAuthSuccessState(RestoreAuthSuccessState event, Emitter<AuthenticationState> emit) async {
    // We cancel existing timer to refresh access token and force refresh it now
    // This is done so that stale user data from previous trigger do not get reused in the refresh call
    _setUpRefreshAccessTokenTrigger(event.tokens, event.user);
    emit(AuthSuccessState(authenticatedUser: event.user));
  }

  void _refreshAccessTokenRequested(RefreshAccessTokenRequested event, Emitter<AuthenticationState> emit) async {
    logger.info("Attempting to refresh the access token");
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final refreshToken = await secureStorage.read(key: event.user.authTokens.refreshTokenSecureStorageKey);
    if (accessToken != null && refreshToken != null) {
      try {
        final newAuthTokens = await authenticationRepository.refreshAccessToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            providerRealm: event.user.user.authProvider
        );
        await secureStorage.write(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY, value: newAuthTokens.accessToken);
        await secureStorage.write(key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY, value: newAuthTokens.refreshToken);
        final newAuthenticatedUser = AuthenticatedUser(
            user: event.user.user,
            userProfile: event.user.userProfile,
            userAgreements: event.user.userAgreements,
            authTokens: SecureAuthTokens.fromAuthTokens(newAuthTokens),
            authProvider: event.user.user.authProvider,
            userTutorialStatus: event.user.userTutorialStatus
        );
        _setUpRefreshAccessTokenTrigger(newAuthTokens, newAuthenticatedUser);
        emit(AuthSuccessUserUpdateState(authenticatedUser: newAuthenticatedUser));
      } catch (e) {
        logger.warning("Could not retrieve refresh token, possible token expiry. Signing out now");
        add(SignOutEvent(user: event.user));
      }
    }
  }

  void _authenticatedUserDataUpdated(AuthenticatedUserDataUpdated event, Emitter<AuthenticationState> emit) async {
    _forceRefreshAccessToken(event.user);
    emit(AuthSuccessUserUpdateState(authenticatedUser: event.user));
  }

  void _signInWithEmail(SignInWithEmailEvent event, Emitter<AuthenticationState> emit) async {
    try {
      emit(const AuthLoadingState());
      final authTokens = await authenticationRepository.basicLogIn(username: event.email, password: event.password);
      final authenticatedUser =
        await _storeTokensAndGetAuthenticatedUser(authTokens, OidcProviderInfo.NATIVE_AUTH_PROVIDER);
      await chatRepository.upsertChatUser(authTokens.accessToken);
      userRepository.trackUserEvent(UserLoggedIn(), authTokens.accessToken);
      _setUpRefreshAccessTokenTrigger(authTokens, authenticatedUser);
      emit(AuthSuccessState(authenticatedUser: authenticatedUser));
    } catch (e) {
      emit(AuthFailureState());
    }
  }

  void _signInWithOidc(SignInWithOidcEvent event, Emitter<AuthenticationState> emit) async {
    final authTokens = await authenticationRepository.oidcLogin(providerRealm: event.provider);
    // We use a try catch block because we can run into OIDC login failures when a user uses the same email they used for NativeAuth, for OAuth
    try {
      emit(const AuthLoadingState());
      final authenticatedUser = await _storeTokensAndGetAuthenticatedUser(authTokens, event.provider);
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await chatRepository.upsertChatUser(accessToken!);
      userRepository.trackUserEvent(UserLoggedIn(), accessToken);
      _setUpRefreshAccessTokenTrigger(authTokens, authenticatedUser);
      emit(AuthSuccessState(authenticatedUser: authenticatedUser));
    } catch (e) {
      emit(AuthConflictState());
    }
  }

  // Refresh auth token 60 seconds before expiry
  void _setUpRefreshAccessTokenTrigger(AuthTokens authTokens, AuthenticatedUser user) {
    _refreshAccessTokenTimer = Timer(Duration(seconds: authTokens.expiresIn - 60), () {
      add(RefreshAccessTokenRequested(user: user));
    });
    _setUpSyncStepsDataRequestedTrigger(user);
  }

  void _setUpSyncStepsDataRequestedTrigger(AuthenticatedUser user) {
    _syncStepsDataTimer?.cancel();
    if (isFirstTimeSync) {
      add(SyncStepsDataRequested(user: user));
      isFirstTimeSync = false;
    }
    _syncStepsDataTimer = Timer(ExerciseUtils.backgroundStepCountSyncDuration, () {
      add(SyncStepsDataRequested(user: user));
    });
  }

  void _forceRefreshAccessToken(AuthenticatedUser user) {
    _refreshAccessTokenTimer?.cancel();
    add(RefreshAccessTokenRequested(user: user));
  }

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
      final userTutorialStatus = await userRepository.getUserTutorialStatus(freshUserId, freshTokens.accessToken);
      return AuthenticatedUser(
          user: user!,
          userProfile: userProfile,
          userAgreements: userAgreements,
          authTokens: SecureAuthTokens.fromAuthTokens(freshTokens),
          authProvider: authRealm,
          userTutorialStatus: userTutorialStatus,
      );
    }
    else {
      final user = await userRepository.getUser(userId, authTokens.accessToken);
      final userProfile = await userRepository.getUserProfile(userId, authTokens.accessToken);
      final userAgreements = await userRepository.getUserAgreements(userId, authTokens.accessToken);
      final userTutorialStatus = await userRepository.getUserTutorialStatus(userId, authTokens.accessToken);
      return AuthenticatedUser(
          user: user!,
          userProfile: userProfile,
          userAgreements: userAgreements,
          authTokens: SecureAuthTokens.fromAuthTokens(authTokens),
          authProvider: authRealm,
          userTutorialStatus: userTutorialStatus,
      );
    }
  }

  void _signOut(SignOutEvent event, Emitter<AuthenticationState> emit) async {
    _signOutWorkflow(event.user.user.id, event.user.authProvider);
    emit(AuthInitialState());
  }

  void _signOutWorkflow(String userId, String authProvider) async {
    _refreshAccessTokenTimer?.cancel();
    _syncStepsDataTimer?.cancel();
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final refreshToken = await secureStorage.read(key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY);
    await authenticationRepository.logout(
      accessToken: accessToken!,
      refreshToken: refreshToken!,
      authRealm: authProvider,
    );

    if (!kIsWeb) {
      // Only unregister device if not web, as we have disabled support for web
      final registrationToken = await FirebaseMessaging.instance.getToken(vapidKey: DefaultFirebaseOptions.vapidKey);
      await notificationRepository.unregisterDeviceToken(userId, registrationToken!, accessToken);
      await FirebaseMessaging.instance.deleteToken();
    }
    userRepository.trackUserEvent(UserLoggedOut(), accessToken);

    await secureStorage.delete(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await secureStorage.delete(key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY);
  }

  void _initiateAuthenticationFlow(InitiateAuthenticationFlow event, Emitter<AuthenticationState> emit,) async {
    final username = event.email.isEmpty ? const Email.pure() : Email.dirty(event.email);
    final password = event.password.isEmpty ? const LoginPassword.pure() : LoginPassword.dirty(event.password);
    final status = Formz.validate([username, password]);
    emit(AuthCredentialsModified(status: status, email: username, password: password));
  }

  void _onUsernameChanged(LoginEmailChanged event, Emitter<AuthenticationState> emit,) {
    final username = Email.dirty(event.email);
    final currentState = state;

    if (currentState is AuthCredentialsModified) {
      emit(currentState.copyWith(
        username: username,
        status: Formz.validate([currentState.password, username]),
      ));
    }
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<AuthenticationState> emit,) {
    final password = LoginPassword.dirty(event.password);
    final currentState = state;

    if (currentState is AuthCredentialsModified) {
      emit(currentState.copyWith(
        password: password,
        status: Formz.validate([password, currentState.email]),
      ));
    }
  }
}
