import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/proxies/custom_proxy.dart';
import 'package:flutter_app/src/models/notification/push_notification.dart';
import 'package:flutter_app/src/repos/rest/authentication_repository.dart';
import 'package:flutter_app/src/repos/rest/image_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/views/complete_profile/complete_profile_page.dart';
import 'package:flutter_app/src/views/reset_password/reset_password_page.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/create_account_page.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/login/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'src/views/login/bloc/authentication_state.dart';

void main() async {
  const String PROXY_IP = "192.168.2.25";

  WidgetsFlutterBinding.ensureInitialized();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  if (kDebugMode) {
    if (Platform.isAndroid) {
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
        RepositoryProvider<ImageRepository>(create: (context) => ImageRepository()),
        RepositoryProvider<FlutterSecureStorage>(create: (context) => const FlutterSecureStorage()),
        RepositoryProvider<AuthenticatedUserStreamRepository>(create: (context) => AuthenticatedUserStreamRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>(
              create: (context) => AuthenticationBloc(
                    authenticationRepository: RepositoryProvider.of<AuthenticationRepository>(context),
                    userRepository: RepositoryProvider.of<UserRepository>(context),
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

  late final FirebaseMessaging _messaging;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'High Importance Notifications', // description
    importance: Importance.max,
  );

  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
      );

      // do something here as app started with push notification
      // https://blog.logrocket.com/add-flutter-push-notifications-firebase-cloud-messaging/
    }
  }

  void registerNotification() async {
    await Firebase.initializeApp();

    _messaging = FirebaseMessaging.instance;

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('food');
    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
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

    // Test, to be
    await _messaging.subscribeToTopic("test-notification-topic");


    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {

        print("*******************************************I");
        print("MESSAGE RECEVIED");
        print("*******************************************I");

        // This object needed or not?
        // PushNotification notification = PushNotification(
        //   title: message.notification?.title,
        //   body: message.notification?.body,
        // );

        RemoteNotification? notification = message.notification;

        AndroidNotification? android = message.notification?.android;

        print(notification);
        print(android);

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: android.smallIcon,
                  // other properties...
                ),
              ));
        }

          // Overlay support needed or not?
          // For displaying the notification as an overlay
          // showSimpleNotification(
          //   Text(_notificationInfo!.title!),
          //   leading: Text(_totalNotifications.toString()),
          //   subtitle: Text(_notificationInfo!.body!),
          //   background: Colors.cyan.shade700,
          //   duration: const Duration(seconds: 2),
          // );
      });

    } else {
      print('User declined or has not accepted permission');
    }
  }

  handleAppInBackgroundWhenNotificationReceived() {
    // For handling notification when the app is in background
    // but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
      );
      // React to message here
      // https://blog.logrocket.com/add-flutter-push-notifications-firebase-cloud-messaging/
    });
  }


  @override
  void initState() {
    super.initState();

    handleAppInBackgroundWhenNotificationReceived();
    registerNotification();
    checkForInitialMessage();
  }


  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
        child: MaterialApp(
          theme: appTheme,
          darkTheme: darkTheme,
          routes: {
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
        )
    );
  }
}

Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
