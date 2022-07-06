import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

class PushNotificationSettings {

  static final logger = Logger("PushNotificationSettings");

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'High Importance Notifications',
    importance: Importance.max,
  );

  static const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('food');
  static const IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();

  static const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  static Future<void> _setUpFlutterLocalNotifications(BuildContext context) async {
    await flutterLocalNotificationsPlugin.initialize(PushNotificationSettings.initializationSettings,
        onSelectNotification: (String? payload) async {
          if (payload != null) {
            print('received notification payload: ---$payload----');
          }
          Navigator.pushAndRemoveUntil(
              context,
              HomePage.route(defaultSelectedTab: HomePageState.notifications),
              (route) => false
          );
        });
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<NotificationSettings> _requestPermissionsIfNeeded(FirebaseMessaging messaging) async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
    return settings;
  }

  static _subscribeToNotificationsIfAllowed(NotificationSettings settings) {
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        reactToNotification(message);
      });
    } else {
      print('User declined or has not accepted permission');
      logger.info('User declined or has not accepted permission');
    }
  }

  // todo - This code does not consider iOS, will have to refactor when that bridge is crossed
  static reactToNotification(RemoteMessage? remoteMessage) {
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

  static _handleNotificationsReceivedWhenAppInBackground() {
    // For handling notification when the app is in background
    // but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      reactToNotification(message);
    });
  }

  // For handling notification when the app is in terminated state
  static Future<void> _checkForInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    reactToNotification(initialMessage);
  }

  // todo - double displaying of notifications?
  //        consider turning off local notifications plugin / re-reading overlay support method
  //        might have to switch to data notifications instead of notification type
  //        as we are showing it explicitly instead of the system doing it
  // todo - notification payloads not coming through
  static setupFirebasePushNotifications(BuildContext context, FirebaseMessaging messaging) async {
    await _setUpFlutterLocalNotifications(context);
    final NotificationSettings settings = await _requestPermissionsIfNeeded(messaging);
    await _subscribeToNotificationsIfAllowed(settings);
    await _handleNotificationsReceivedWhenAppInBackground();
    await _checkForInitialMessage();
  }
}

Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  PushNotificationSettings.reactToNotification(message);
}