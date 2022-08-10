import 'dart:io';

import 'package:badges/badges.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/firebase/firebase_options.dart';
import 'package:flutter_app/src/infrastructure/firebase/push_notification_settings.dart';
import 'package:flutter_app/src/models/device/local_device_info.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/push/notification_device.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/chat_home/chat_home_view.dart';
import 'package:flutter_app/src/views/discover_home/discover_home_view.dart';
import 'package:flutter_app/src/views/newsfeed/newsfeed_view.dart';
import 'package:flutter_app/src/views/account_details/account_details_view.dart';
import 'package:flutter_app/src/views/followers/followers_view.dart';
import 'package:flutter_app/src/views/following/following_view.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_bloc.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/notifications/notifications_view.dart';
import 'package:flutter_app/src/views/search/search_view.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.defaultSelectedTab = HomePageState.newsFeed}) : super(key: key);

  static const String routeName = 'home';

  final String defaultSelectedTab;

  static Route route({String defaultSelectedTab = HomePageState.newsFeed}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(
        name: routeName
      ),
      builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<MenuNavigationBloc>(create: (context) => MenuNavigationBloc(
                notificationRepository: RepositoryProvider.of<NotificationRepository>(context),
                secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context)
              )),
            ],
            child: HomePage(defaultSelectedTab: defaultSelectedTab),
          )
    );
  }

  @override
  State createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  static const String accountDetails = 'Account Details';
  static const String notifications = 'Notifications';
  static const String discover = 'Discover';
  static const String search = 'Search';
  static const String followers = 'Followers';
  static const String following = 'Following';
  static const String newsFeed = 'News Feed';
  static const String chat = 'Chat';
  static const String logout = 'Logout';

  final logger = Logger("HomePageState");

  late String selectedMenuItem;
  late int unreadNotificationCount;

  UserProfile? userProfile;

  late AuthenticationBloc _authenticationBloc;
  late MenuNavigationBloc _menuNavigationBloc;

  late NotificationRepository _notificationRepository;
  late FlutterSecureStorage _secureStorage;

  void syncDeviceRegistrationToken() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    LocalDeviceInfo localDeviceInfo;

    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        localDeviceInfo = LocalDeviceInfo(
            manufacturer: androidInfo.manufacturer!,
            model: androidInfo.model!,
            isPhysicalDevice: androidInfo.isPhysicalDevice!);
      } else {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        localDeviceInfo =
            LocalDeviceInfo(manufacturer: "Apple", model: iosInfo.model!, isPhysicalDevice: iosInfo.isPhysicalDevice);
      }
    }
    else {
      // Web app
      final webInfo = await deviceInfoPlugin.webBrowserInfo;
      localDeviceInfo = LocalDeviceInfo(manufacturer: "Web", model: webInfo.browserName.name, isPhysicalDevice: false);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      _syncTokenWithServer(token, localDeviceInfo);
    });
    String? token = await FirebaseMessaging.instance.getToken(vapidKey: DefaultFirebaseOptions.vapidKey);
    _syncTokenWithServer(token!, localDeviceInfo);
  }

  void _syncTokenWithServer(String token, LocalDeviceInfo localDeviceInfo) async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      NotificationDevice deviceInfo = NotificationDevice(
          userId: currentAuthState.authenticatedUser.user.id,
          registrationToken: token,
          manufacturer: localDeviceInfo.manufacturer,
          model: localDeviceInfo.model,
          isPhysicalDevice: localDeviceInfo.isPhysicalDevice
      );
      final accessToken =
      await _secureStorage.read(key: currentAuthState.authenticatedUser.authTokens.accessTokenSecureStorageKey);
      await _notificationRepository.registerDeviceToken(deviceInfo, accessToken!);
    }
  }

  @override
  void initState() {
    super.initState();

    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _menuNavigationBloc = BlocProvider.of<MenuNavigationBloc>(context);

    _notificationRepository = RepositoryProvider.of<NotificationRepository>(context);
    _secureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);

    selectedMenuItem = widget.defaultSelectedTab;
    unreadNotificationCount = 0;
    _updateBloc(selectedMenuItem);

    PushNotificationSettings.setupFirebasePushNotifications(context, FirebaseMessaging.instance);
  }

  _updateAppBadgeIfPossible() async {
    if (DeviceUtils.isMobileDevice()) {
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (isSupported) {
        FlutterAppBadger.updateBadgeCount(unreadNotificationCount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthSuccessUserUpdateState) {
          userProfile = state.authenticatedUser.userProfile;
          syncDeviceRegistrationToken();
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          return BlocBuilder<MenuNavigationBloc, MenuNavigationState>(
              builder: (BuildContext context, MenuNavigationState state) {
                if (state is MenuItemSelected) {
                  selectedMenuItem = state.selectedMenuItem;
                  unreadNotificationCount = state.unreadNotificationCount;
                  _updateAppBadgeIfPossible();
                }
                return Scaffold(
                  appBar: AppBar(
                    title: Text(selectedMenuItem, style: const TextStyle(color: Colors.teal),),
                    iconTheme: const IconThemeData(color: Colors.teal),
                    actions: <Widget>[
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.teal,
                        ),
                        onPressed: () {
                          _updateBloc(search);
                        },
                      )
                    ],
                  ),
                  drawer: Drawer(
                    child: Column(
                      children: [
                        _drawerHeader(),
                        Expanded(child: _menuDrawerListItems()),
                        const Divider(),
                        _bottomAlignedButtons(),
                      ],
                    ),
                  ),
                  body: _generateBody(selectedMenuItem),
                );
              });
        },
      ),
    );
  }

  Widget _bottomAlignedButtons() {
    return Align(
        alignment: FractionalOffset.bottomCenter,
        // This container holds all the children that will be aligned
        // on the bottom and should not scroll with the above ListView
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                _signOutIfApplicable();
              },
            )
          ],
        )
    );
  }

  Widget _drawerHeader() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(builder: (context, state) {
      return SizedBox(
        height: 200,
        child: DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.teal,
          ),
          child: Column(
            children: [
              _userFirstAndLastName(state),
              _userProfileImage(state),
              _settingsIcon()
            ],
          ),
        ),
      );
    });
  }

  _updateBloc(String selectedItem) {
    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      _menuNavigationBloc.add(
          MenuItemChosen(
              selectedMenuItem: selectedItem  ,
              currentUserId: currentState.authenticatedUser.user.id
          )
      );
    }
  }

  _settingsIcon() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (selectedMenuItem != accountDetails) {
          final currentState = _authenticationBloc.state;
          if (currentState is AuthSuccessUserUpdateState) {
            _menuNavigationBloc.add(
                MenuItemChosen(
                    selectedMenuItem: accountDetails,
                    currentUserId: currentState.authenticatedUser.user.id
                )
            );
          }
        }
      },
      child: const Align(
        alignment: Alignment.bottomRight,
        child: Icon(Icons.settings),
      ),
    );
  }

  _userFirstAndLastName(AuthenticationState state) {
    String firstName = "";
    String lastName = "";
    if (state is AuthSuccessUserUpdateState) {
      firstName = state.authenticatedUser.userProfile?.firstName ?? "";
      lastName = state.authenticatedUser.userProfile?.lastName ?? "";
    }
    return Expanded(
        flex: 1,
        child: Text(
          "$firstName $lastName",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ));
  }

  Widget _userProfileImage(AuthenticationState state) {
    return Expanded(
        flex: 2,
        child: Center(
          child: GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              if (selectedMenuItem != accountDetails) {
                _updateBloc(accountDetails);
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
          )
        )
    );
  }

  _getDecorationImage(AuthenticationState state) {
    if (state is AuthSuccessUserUpdateState) {
      final photoUrlOpt = state.authenticatedUser.userProfile?.photoUrl;
      if (photoUrlOpt != null) {
        return DecorationImage(
            image: NetworkImage("${ImageUtils.imageBaseUrl}/$photoUrlOpt?transform=100x100"), fit: BoxFit.fitHeight);
      }
    } else {
      return null;
    }
  }

  Widget _generateListTile(String text) {
    final Widget element;
    if (text == notifications && unreadNotificationCount != 0) {
      element = Badge(
        alignment: Alignment.centerLeft,
        badgeContent: Text(unreadNotificationCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(10),
        child: Text(text),
      );
    }
    else {
      element = Text(text);
    }
    return ListTile(
      title: element,
      onTap: () {
        Navigator.pop(context);
        if (selectedMenuItem != text) {
          _updateBloc(text);
        }
      },
    );
  }

  Widget _menuDrawerListItems() {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: <Widget>[
        _generateListTile(notifications),
        _generateListTile(search),
        _generateListTile(discover),
        _generateListTile(followers),
        _generateListTile(following),
        _generateListTile(newsFeed),
        _generateListTile(chat),
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
    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      final publicUserProfile = PublicUserProfile(
          authState.authenticatedUser.user.id,
          authState.authenticatedUser.user.username,
          authState.authenticatedUser.userProfile?.firstName,
          authState.authenticatedUser.userProfile?.lastName,
          authState.authenticatedUser.userProfile?.photoUrl,
          authState.authenticatedUser.userProfile?.locationRadius,
          authState.authenticatedUser.userProfile?.locationCenter,
          authState.authenticatedUser.userProfile?.gender,
      );
      switch (selectedMenuItem) {
        case "Account Details":
          return AccountDetailsView.withBloc();
        case "Notifications":
          return NotificationsView.withBloc(publicUserProfile);
        case "Search":
          return SearchView.withBloc(publicUserProfile);
        case "Followers":
          return FollowersView.withBloc(publicUserProfile);
        case "Following":
          return FollowingUsersView.withBloc(publicUserProfile);
        case "News Feed":
          return NewsFeedView.withBloc(publicUserProfile);
        case "Chat":
          return ChatHomeView.withBloc(publicUserProfile);
        case "Discover":
          return DiscoverHomeView.withBloc(publicUserProfile);
        default:
          return _oldStuff();
      }
    }
    else {
      return const Center(
        child: Text("Bad State"),
      );
    }
  }

  _oldStuff() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              if (state is AuthSuccessUserUpdateState) {
                return Text('UserID: ${state.authenticatedUser.user}');
              } else {
                return const Text('Forbidden state!');
              }
            },
          ),
        ],
      ),
    );
  }
}
