import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/views/account_details/account_details_view.dart';
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
        builder: (_) =>
            MultiBlocProvider(
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

  UserProfile? userProfile;

  late AuthenticationBloc _authenticationBloc;
  late MenuNavigationBloc _menuNavigationBloc;

  @override
  void initState() {
    super.initState();
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _menuNavigationBloc = BlocProvider.of<MenuNavigationBloc>(context);

    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessState) {
      userProfile = currentAuthState.authenticatedUser.userProfile;
    } else if (currentAuthState is AuthSuccessUserUpdateState) {
      userProfile = currentAuthState.authenticatedUser.userProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuNavigationBloc, MenuNavigationState>(
        builder: (BuildContext context, MenuNavigationState state) {
          if (state is MenuItemSelected) {
            selectedMenuItem = state.selectedMenuItem;
          }
          return Scaffold(
            appBar: AppBar(title: Text(selectedMenuItem)),
            drawer: Drawer(
              child: _menuDrawerListItems(),
            ),
            body: _generateBody(selectedMenuItem),
          );
        });
  }

  Widget _drawerHeader() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          return SizedBox(
            height: 200,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.teal,
              ),
              child: Column(
                children: [
                  _userFirstAndLastName(state),
                  Expanded(flex: 2, child: Center(child: _userProfileImage(state))),
                  _settingsIcon()
                ],
              ),
            ),
          );
        });
  }

  _settingsIcon() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (selectedMenuItem != accountDetails) {
          _menuNavigationBloc.add(const MenuItemChosen(selectedMenuItem: accountDetails));
        }
      },
      child: const Align(
        alignment: Alignment.bottomRight,
        child: Icon(
            Icons.settings
        ),
      ),
    );
  }

  _userFirstAndLastName(AuthenticationState state) {
    String firstName = "";
    String lastName = "";
    if (state is AuthSuccessState) {
      firstName = state.authenticatedUser.userProfile?.firstName ?? "";
      lastName = state.authenticatedUser.userProfile?.lastName ?? "";
    } else if (state is AuthSuccessUserUpdateState) {
      firstName = state.authenticatedUser.userProfile?.firstName ?? "";
      lastName = state.authenticatedUser.userProfile?.lastName ?? "";
    }
    return Expanded(
        flex: 1,
        child: Text(
          "$firstName $lastName",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        )
    );
  }

  Widget _userProfileImage(AuthenticationState state) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        if (selectedMenuItem != accountDetails) {
          _menuNavigationBloc.add(const MenuItemChosen(selectedMenuItem: accountDetails));
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: _getDecorationImage(state),
        ),
      ),
    );
  }

  _getDecorationImage(AuthenticationState state) {
    if (state is AuthSuccessState) {
      final photoUrlOpt = state.authenticatedUser.userProfile?.photoUrl;
      if (photoUrlOpt != null) {
        return DecorationImage(image: NetworkImage("$imageBaseUrl/100x100/$photoUrlOpt"), fit: BoxFit.fitHeight);
      }
    } else if (state is AuthSuccessUserUpdateState) {
      final photoUrlOpt = state.authenticatedUser.userProfile?.photoUrl;
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
            _signOutIfApplicable();
          },
        ),
      ],
    );
  }

  void _signOutIfApplicable() {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _authenticationBloc.add(SignOutEvent(user: currentAuthState.authenticatedUser));
    } else if (currentAuthState is AuthSuccessState) {
      _authenticationBloc.add(SignOutEvent(user: currentAuthState.authenticatedUser));
    }
  }

  Widget _generateBody(String selectedMenuItem) {
    switch (selectedMenuItem) {
      case "Account Details":
        return AccountDetailsView.withBloc();
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
        ],
      ),
    );
  }
}
