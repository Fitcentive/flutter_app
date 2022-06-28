import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_bloc.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../login/bloc/authentication_bloc.dart';
import '../login/bloc/authentication_event.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider<MenuNavigationBloc>(create: (context) => MenuNavigationBloc()),
              ],
              child: const HomePage(),
            ));
  }

  @override
  State createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  static const String accountDetails = 'Account Details';
  static const String otherPage = 'OtherPage';
  static const String logout = 'Logout';

  static const String imageBaseUrl = "http://api.vid.app/api/images";

  String selectedMenuItem = otherPage;

  late AuthenticationBloc _authenticationBloc;
  late MenuNavigationBloc _menuNavigationBloc;

  @override
  void initState() {
    super.initState();
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _menuNavigationBloc = BlocProvider.of<MenuNavigationBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuNavigationBloc, MenuNavigationState>(
        builder: (BuildContext context, MenuNavigationState state) {
          if (state is MenuItemSelected) {
            selectedMenuItem = state.selectedMenuItem;
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            drawer: Drawer(
              child: _menuDrawerListItems(),
            ),
            body: _generateBody(selectedMenuItem),
          );
    });
  }

  Widget _drawerHeader() => SizedBox(
        height: 300,
        child: DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.teal,
          ),
          child: Column(
            children: [
              const Expanded(
                  flex: 3,
                  child: Center(
                      child: Text(
                    "Fitcentive",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ))),
              Expanded(flex: 8, child: Center(child: _circleImageView("", ""))),
              const Expanded(
                flex: 1,
                child: Text("v1.0.0"),
              )
            ],
          ),
        ),
      );

  Widget _circleImageView(String url, String assetUrl) {
    return GestureDetector(
      onTap: () async {
        print("No implementation for onTap yet");
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: _getDecorationImage(),
        ),
      ),
    );
  }

  _getDecorationImage() {
    final authCurrentState = _authenticationBloc.state;
    if (authCurrentState is AuthSuccessState) {
      final photoUrlOpt = authCurrentState.authenticatedUser.userProfile?.photoUrl;
      if (photoUrlOpt != null) {
        return DecorationImage(image: NetworkImage("$imageBaseUrl/100x100/$photoUrlOpt"), fit: BoxFit.fitHeight);
      }
    } else if (authCurrentState is AuthSuccessUserUpdateState) {
      final photoUrlOpt = authCurrentState.authenticatedUser.userProfile?.photoUrl;
      if (photoUrlOpt != null) {
        return DecorationImage(image: NetworkImage("$imageBaseUrl/100x100/$photoUrlOpt"), fit: BoxFit.fitHeight);
      }
    } else {
      return null;
    }
  }

  Widget _menuDrawerListItems() {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _drawerHeader(),
        ListTile(
          title: const Text(accountDetails),
          onTap: () {
            Navigator.pop(context);
            if (selectedMenuItem != accountDetails) {
              _menuNavigationBloc.add(const MenuItemChosen(selectedMenuItem: accountDetails));
            }
          },
        ),
        ListTile(
          title: const Text(otherPage),
          onTap: () {
            Navigator.pop(context);
            if (selectedMenuItem != otherPage) {
              _menuNavigationBloc.add(const MenuItemChosen(selectedMenuItem: otherPage));
            }
          },
        ),
        ListTile(
          title: const Text("Logout"),
          onTap: () {
            Navigator.pop(context);
            final currentAuthState = _authenticationBloc.state;
            if (currentAuthState is AuthSuccessUserUpdateState) {
              _authenticationBloc.add(SignOutEvent(user: currentAuthState.authenticatedUser));
            } else if (currentAuthState is AuthSuccessState) {
              _authenticationBloc.add(SignOutEvent(user: currentAuthState.authenticatedUser));
            }
          },
        ),
      ],
    );
  }

  Widget _generateBody(String selectedMenuItem) {
    switch (selectedMenuItem) {
      case "Account Details":
        return const Text("Coming Soon");
      default:
        return _oldStuff();
    }
  }

  _oldStuff() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Builder(
            builder: (context) {
              final currentAuthBlocState = context.select((AuthenticationBloc bloc) => bloc.state);
              if (currentAuthBlocState is AuthSuccessState) {
                return Text('UserID: ${currentAuthBlocState.authenticatedUser.user}');
              } else if (currentAuthBlocState is AuthSuccessUserUpdateState) {
                return Text('UserID: ${currentAuthBlocState.authenticatedUser.user}');
              } else {
                return Text('Forbidden state!');
              }
            },
          ),
          ElevatedButton(
            child: const Text('Logout'),
            onPressed: () {
              final currentAuthBlocState = _authenticationBloc.state;
              if (currentAuthBlocState is AuthSuccessState) {
                _authenticationBloc.add(SignOutEvent(user: currentAuthBlocState.authenticatedUser));
              } else if (currentAuthBlocState is AuthSuccessUserUpdateState) {
                _authenticationBloc.add(SignOutEvent(user: currentAuthBlocState.authenticatedUser));
              }
            },
          ),
        ],
      ),
    );
  }
}
