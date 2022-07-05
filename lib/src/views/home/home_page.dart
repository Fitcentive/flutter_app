import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/device/local_device_info.dart';
import 'package:flutter_app/src/models/notification/notification_device.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/account_details/account_details_view.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_bloc.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

// todo - figure out if this is needed
Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
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

  late NotificationRepository _notificationRepository;
  late FlutterSecureStorage _secureStorage;

  late final FirebaseMessaging _messaging;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'High Importance Notifications',
    importance: Importance.max,
  );

  void checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    reactToNotification(initialMessage);
  }

  void registerNotification() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('food');
    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      if (payload != null) {
        print('received notification payload: $payload');
      }
    });
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        reactToNotification(message);
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // todo - handle ios specific notification data
  void reactToNotification(RemoteMessage? remoteMessage) {
    if (remoteMessage != null) {
      RemoteNotification? notification = remoteMessage.notification;
      AndroidNotification? android = remoteMessage.notification?.android;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android?.smallIcon,
              ),
            ));
      }
    }
  }

  void handleAppInBackgroundWhenNotificationReceived() {
    // For handling notification when the app is in background
    // but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      reactToNotification(message);
    });
  }

  void syncDeviceRegistrationToken() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    LocalDeviceInfo localDeviceInfo;
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
    _messaging.onTokenRefresh.listen((String token) async {
      _syncTokenWithServer(token, localDeviceInfo);
    });
    String? token = await _messaging.getToken();
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
          isPhysicalDevice: localDeviceInfo.isPhysicalDevice);
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

    registerNotification();
    handleAppInBackgroundWhenNotificationReceived();
    checkForInitialMessage();
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
      child: BlocBuilder<MenuNavigationBloc, MenuNavigationState>(
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
      }),
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
