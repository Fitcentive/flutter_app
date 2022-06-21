import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../authentication/bloc/authentication_bloc.dart';
import '../authentication/bloc/authentication_event.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);


  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => HomePage());
  }

  @override
  State createState() {
    return HomePageState();
  }
}


class HomePageState extends State<HomePage> {

  late AuthenticationBloc _authenticationBloc;


  @override
  void initState() {
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(
              builder: (context) {
                final currentAuthBlocState = context.select((AuthenticationBloc bloc) => bloc.state);
                if (currentAuthBlocState is AuthSuccessState) {
                  return Text('UserID: ${currentAuthBlocState.authenticatedUser.user.id}');
                }
                else {
                  return Text('Forbidden state!');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Logout'),
              onPressed: () {
                final currentAuthBlocState = _authenticationBloc.state;
                if (currentAuthBlocState is AuthSuccessState)  {
                  _authenticationBloc
                      .add(SignOutEvent(user: currentAuthBlocState.authenticatedUser));
                }
                else {
                  throw Exception("sdffdf");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
