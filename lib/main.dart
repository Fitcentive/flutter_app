import 'package:flutter/material.dart';
import 'package:flutter_app/src/repos/authentication_repository.dart';
import 'package:flutter_app/src/repos/user_repository.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/create_account_page.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/login/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthenticationRepository>(create: (context) => AuthenticationRepository()),
        RepositoryProvider<UserRepository>(create: (context) => UserRepository()),
        RepositoryProvider<FlutterSecureStorage>(create: (context) => const FlutterSecureStorage())
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>(
              create: (context) => AuthenticationBloc(
                authenticationRepository: RepositoryProvider.of<AuthenticationRepository>(context),
                userRepository: RepositoryProvider.of<UserRepository>(context),
                secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
              )
          ),
          BlocProvider<CreateAccountBloc>(create: (context) =>
              CreateAccountBloc(userRepository: RepositoryProvider.of<UserRepository>(context))
          )
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
        '/create-account': (context) => const CreateAccountPage(),
      },
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthSuccessState) {
              _navigator.pushAndRemoveUntil<void>(
                HomePage.route(),
                (route) => false,
              );
            } else if (state is AuthInitialState) {
              _navigator.pushAndRemoveUntil<void>(
                LoginPage.route(),
                (route) => false,
              );
            }
          },
          child: child,
        );
      },
      onGenerateRoute: (_) {
        return LoginPage.route();
      },
    );
  }
}
