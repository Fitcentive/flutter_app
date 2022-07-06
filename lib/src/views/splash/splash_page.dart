import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/repos/rest/authentication_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/jwt_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/login/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class SplashPage extends StatefulWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => SplashPage());
  }

  @override
  State createState() {
    return SplashPageState();
  }
}

class SplashPageState extends State<SplashPage> {
  late AuthenticationBloc _authenticationBloc;
  late FlutterSecureStorage _secureStorage;
  late AuthenticationRepository _authenticationRepository;
  late UserRepository _userRepository;

  final logger = Logger("SplashPage");

  @override
  void initState() {
    super.initState();
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _secureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);
    _authenticationRepository = RepositoryProvider.of<AuthenticationRepository>(context);
    _userRepository = RepositoryProvider.of<UserRepository>(context);
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/launcher/icon.png"),
            fit: BoxFit.contain
        ),
      ),
    ));
  }

  void startTimer() {
    Timer(const Duration(seconds: 1, milliseconds: 500), () {
      navigateUser(context);
    });
  }

  void navigateUser(BuildContext context) async {
    final navigator = Navigator.of(context);
    final accessTokenOpt = await _secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final refreshTokenOpt = await _secureStorage.read(key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY);
    try {
      final userId = JwtUtils.getUserIdFromJwtToken(accessTokenOpt!);
      final authRealm = JwtUtils.getAuthRealmFromJwtToken(accessTokenOpt);
      final freshTokens = await _authenticationRepository.refreshAccessToken(
          accessToken: accessTokenOpt, refreshToken: refreshTokenOpt!, providerRealm: authRealm!);

      await _secureStorage.write(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY, value: freshTokens.accessToken);
      await _secureStorage.write(key: SecureAuthTokens.REFRESH_TOKEN_SECURE_STORAGE_KEY, value: freshTokens.refreshToken);

      final user = await _userRepository.getUser(userId!, freshTokens.accessToken);
      final userProfile = await _userRepository.getUserProfile(userId, freshTokens.accessToken);
      final userAgreements = await _userRepository.getUserAgreements(userId, freshTokens.accessToken);
      final secureAuthTokens = SecureAuthTokens.fromAuthTokens(freshTokens);

      final authenticatedUser = AuthenticatedUser(
          user: user!,
          userProfile: userProfile,
          userAgreements: userAgreements,
          authTokens: secureAuthTokens,
          authProvider: authRealm
      );

      _authenticationBloc.add(RestoreAuthSuccessState(user: authenticatedUser, tokens: freshTokens));
    } catch (ex) {
      print("An exception occurred when trying to restore auth state, proceeding with normal flow. Exception: ${ex.toString()}");
      logger.info("An exception occurred when trying to restore auth state, proceeding with normal flow. Exception: ${ex.toString()}");
    } finally {
      WidgetsFlutterBinding.ensureInitialized();
      navigator.pushReplacement(LoginPage.route());
    }
  }
}
