import 'package:flutter/material.dart';
import 'package:flutter_app/src/repos/authentication_repository.dart';
import 'package:flutter_app/src/repos/user_repository.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/login/login_page.dart';
import 'package:flutter_app/src/views/splash/splash_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(App(
    authenticationRepository: AuthenticationRepository(),
    userRepository: UserRepository(),
  ));
}

class App extends StatelessWidget {
  const App({
    Key? key,
    required this.authenticationRepository,
    required this.userRepository,
  }) : super(key: key);

  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authenticationRepository,
      child: BlocProvider(
        create: (_) => AuthenticationBloc(
          authenticationRepository: authenticationRepository,
          userRepository: userRepository,
        ),
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
    print("Widget build is being run now");
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            print("Listener callback is being run now");
            if (state is AuthSuccessState) {
              print("AUTH SUCCESS STATE FOUND");
              print(state.authenticatedUser);
              _navigator.pushAndRemoveUntil<void>(
                HomePage.route(),
                    (route) => false,
              );
            }
            else if (state is AuthInitialState) {
              print("IN AUTHENTICATION STATE");
              _navigator.pushAndRemoveUntil<void>(
                LoginPage.route(),
                    (route) => false,
              );
            }
            else {
              print("IN THE DEFAULT CASE");
              print(state);
            }
          },
          child: child,
        );
      },
      onGenerateRoute: (_) {
        print("ON GENERATE ROUTE");
        return LoginPage.route();
      },
    );
  }
}
