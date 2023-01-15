import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/firebase/firebase_options.dart';
import 'package:flutter_app/src/infrastructure/proxies/custom_proxy.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/authentication_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/image_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/views/complete_profile/complete_profile_page.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/reset_password/reset_password_page.dart';
import 'package:flutter_app/src/views/splash/splash_page.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/create_account_page.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/login/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      name: "dev-flutter-app",
      options: DefaultFirebaseOptions.currentPlatform
  );
  // await _initializeProxy();
  runApp(const App());
}

_initializeProxy() async {
  const String PROXY_IP = "192.168.2.25"; // 119
  // const String PROXY_IP = "192.168.0.10"; // 137
  // const String PROXY_IP = "192.168.29.93"; // Velachery


  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  if (kDebugMode) {
    if (DeviceUtils.isMobileDevice()) {
      if (Platform.isAndroid) {
        AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
        final androidInfo = await deviceInfoPlugin.androidInfo;
        if (androidInfo.isPhysicalDevice ?? false) {
          final proxy = CustomProxy(ipAddress: PROXY_IP, port: 8888);
          proxy.enable();
        }
      }
      else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        if (iosInfo.isPhysicalDevice) {
          final proxy = CustomProxy(ipAddress: PROXY_IP, port: 8888);
          proxy.enable();
        }
      }
    }
  }
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthenticationRepository>(create: (context) => AuthenticationRepository()),
        RepositoryProvider<DiscoverRepository>(create: (context) => DiscoverRepository()),
        RepositoryProvider<UserRepository>(create: (context) => UserRepository()),
        RepositoryProvider<ChatRepository>(create: (context) => ChatRepository()),
        RepositoryProvider<ImageRepository>(create: (context) => ImageRepository()),
        RepositoryProvider<SocialMediaRepository>(create: (context) => SocialMediaRepository()),
        RepositoryProvider<NotificationRepository>(create: (context) => NotificationRepository()),
        RepositoryProvider<FlutterSecureStorage>(create: (context) => const FlutterSecureStorage()),
        RepositoryProvider<AuthenticatedUserStreamRepository>(create: (context) => AuthenticatedUserStreamRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>(
              create: (context) => AuthenticationBloc(
                    authenticationRepository: RepositoryProvider.of<AuthenticationRepository>(context),
                    notificationRepository: RepositoryProvider.of<NotificationRepository>(context),
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    chatRepository: RepositoryProvider.of<ChatRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                    authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
                  )),
          BlocProvider<CreateAccountBloc>(
              create: (context) => CreateAccountBloc(userRepository: RepositoryProvider.of<UserRepository>(context))),
        ],
        child: AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  @override
  _AppViewState createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      darkTheme: darkTheme,
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/complete-profile': (context) => const CompleteProfilePage(),
      },
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthSuccessState) {
              _navigator.pushAndRemoveUntil<void>(
                CompleteProfilePage.route(),
                    (route) => false,
              );
            } else if (state is AuthInitialState) {
              _navigator.popAndPushNamed('/login');
            }
          },
          child: child,
        );
      },
      onGenerateRoute: (_) {
        return SplashPage.route();
      },
    );
  }
}

