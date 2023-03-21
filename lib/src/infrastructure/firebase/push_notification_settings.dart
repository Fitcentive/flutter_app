import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/notification/push_notification_metadata.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/push/chat_message_push_notification_metadata.dart';
import 'package:flutter_app/src/models/push/participant_added_to_meetup_push_notification_metadata.dart';
import 'package:flutter_app/src/models/push/user_friend_request_push_notification_metadata.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http;

class PushNotificationSettings {

  static final logger = Logger("PushNotificationSettings");

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'High Importance Notifications',
    importance: Importance.max,
  );

  static void onDidReceiveLocalNotification(BuildContext context, int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Ok'),
            onPressed: () async {
              // do something here
            },
          )
        ],
      ),
    );
  }

  static _openRequestingUserProfileView(
      context,
      FlutterSecureStorage secureStorage,
      UserRepository userRepository,
      String payload
  ) async {
    final notificationMetadata = UserFriendRequestPushNotificationMetadata.fromJson(jsonDecode(payload));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userProfiles = await userRepository.getPublicUserProfiles(
        [notificationMetadata.requestingUserId, notificationMetadata.targetUserId],
        accessToken!
    );
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfiles) (e).userId : e };
    final currentUserProfile = userIdProfileMap[notificationMetadata.targetUserId];
    final otherUserProfile = userIdProfileMap[notificationMetadata.requestingUserId];

    Navigator.pushAndRemoveUntil(
        context,
        UserProfileView.route(otherUserProfile!, currentUserProfile!),
            (route) => true
    );
  }

  static _openDetailedMeetupView(
      context,
      FlutterSecureStorage secureStorage,
      UserRepository userRepository,
      MeetupRepository meetupRepository,
      String payload
      ) async {
    final notificationMetadata = ParticipantAddedToMeetupPushNotificationMetadata.fromJson(jsonDecode(payload));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final currentUserProfile = await userRepository.getPublicUserProfiles([notificationMetadata.participantId], accessToken!);

    Navigator.pushAndRemoveUntil(
        context,
        DetailedMeetupView.route(
            meetupId: notificationMetadata.meetupId,
            currentUserProfile: currentUserProfile.first,
        ),
        (route) => true
    );
  }

  static _openUserChatView(
      BuildContext context,
      FlutterSecureStorage secureStorage,
      UserRepository userRepository,
      String payload
      ) async {
    final notificationMetadata = ChatMessagePushNotificationMetadata.fromJson(jsonDecode(payload));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userProfiles = await userRepository.getPublicUserProfiles(
        [notificationMetadata.targetUserId, notificationMetadata.sendingUserId],
        accessToken!
    );
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfiles) (e).userId : e };
    final currentUserProfile = userIdProfileMap[notificationMetadata.targetUserId];
    final otherUserProfile = userIdProfileMap[notificationMetadata.sendingUserId];

    Navigator.pushAndRemoveUntil(
        context,
        UserChatView.route(
          currentRoomId: notificationMetadata.roomId,
          currentUserProfile: currentUserProfile!,
          otherUserProfile: otherUserProfile!,
        ),
            (route) => true
    );
  }

  static _openNotificationsView(BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context,
        HomePage.route(defaultSelectedTab: HomePageState.notifications),
            (route) => false
    );
  }

  static _getSettings(BuildContext context) {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) {
          onDidReceiveLocalNotification(context, id, title ?? "", body ?? "", payload ?? "");
        }
    );

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS
    );
    return initializationSettings;
  }

  static Future<void> _setUpFlutterLocalNotifications(BuildContext context) async {
    final userRepository = RepositoryProvider.of<UserRepository>(context);
    final secureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);

    final initializationSettings = _getSettings(context);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
          if (payload != null) {
            final pushNotificationMetadata = PushNotificationMetadata.fromJson(jsonDecode(payload));
            switch(pushNotificationMetadata.type) {
              case "user_follow_request":
                _openNotificationsView(context);
                break;

              case "chat_message":
                _openUserChatView(context, secureStorage, userRepository, payload);
                break;

              case "participant_added_to_meetup":
                _openNotificationsView(context);
                break;

              default:
                break;
            }
          }
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

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    const fallback = "https://images.freeimages.com/images/large-previews/4ba/healthy-food-1327899.jpg";

    final directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    http.Response response;
    try {
      response = await http.get(Uri.parse(url));
    } catch (e) {
      response = await http.get(Uri.parse(fallback));
    }

    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static _handleShowingNotification(RemoteNotification? notification, String imageUrl, String payload) async {
    final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');

    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      hideExpandedLargeIcon: false,
      contentTitle: notification?.title,
      summaryText: notification?.body,
    );

    AndroidNotification? android = notification?.android;
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: android?.smallIcon,
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        styleInformation: bigPictureStyleInformation
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformChannelSpecifics,
          payload: payload
      );
    }
  }

  static reactToNotification(RemoteMessage? remoteMessage) async {
    if (remoteMessage != null && DeviceUtils.isMobileDevice()) {
      RemoteNotification? notification = remoteMessage.notification;
      final jsonPayload = jsonEncode(remoteMessage.data);
      final pushNotificationMetadata = PushNotificationMetadata.fromJson(jsonDecode(jsonPayload));

      switch(pushNotificationMetadata.type) {
        case "chat_message":
          final notificationMetadata = ChatMessagePushNotificationMetadata.fromJson(jsonDecode(jsonPayload));
          if (DeviceUtils.isMobileDevice() && Platform.isAndroid) {
            _handleShowingNotification(notification, notificationMetadata.sendingUserPhotoUrl, jsonPayload);
          }
          break;

        case "user_follow_request":
          final notificationMetadata = UserFriendRequestPushNotificationMetadata.fromJson(jsonDecode(jsonPayload));
          if (DeviceUtils.isMobileDevice() && Platform.isAndroid) {
            _handleShowingNotification(notification, notificationMetadata.requestingUserPhotoUrl, jsonPayload);
          }
          break;

        case "participant_added_to_meetup":
          final notificationMetadata = ParticipantAddedToMeetupPushNotificationMetadata.fromJson(jsonDecode(jsonPayload));
          if (DeviceUtils.isMobileDevice() && Platform.isAndroid) {
            _handleShowingNotification(notification, notificationMetadata.meetupOwnerPhotoUrl, jsonPayload);
          }
          break;

        default:
          break;
      }
    }
    else {
      // Dumb it down for web implementation (no image)
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
              ),
              payload: jsonEncode(remoteMessage.data).toString()
          );
        }
      }
    }
  }

  // When auto delivered push notification is selected, this callback is invoked
  static _handleNotificationsReceivedWhenAppInBackground(BuildContext context) {
    final userRepository = RepositoryProvider.of<UserRepository>(context);
    final meetupRepository = RepositoryProvider.of<MeetupRepository>(context);
    final secureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // reactToNotification(message);
      final pushNotificationMetadata = PushNotificationMetadata.fromJson(message.data);
      switch(pushNotificationMetadata.type) {
        case "user_follow_request":
          _openRequestingUserProfileView(context, secureStorage, userRepository, jsonEncode(message.data));
          break;

        case "chat_message":
          _openUserChatView(context, secureStorage, userRepository, jsonEncode(message.data));
          break;

        case "participant_added_to_meetup":
          _openDetailedMeetupView(context, secureStorage, userRepository, meetupRepository, jsonEncode(message.data));
          break;

        default:
          break;
      }
    });
  }

  // For handling notification when the app is in terminated state
  static Future<void> _checkForInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    reactToNotification(initialMessage);
  }

  static setupFirebasePushNotifications(BuildContext context, FirebaseMessaging messaging) async {
    await _setUpFlutterLocalNotifications(context);
    final NotificationSettings settings = await _requestPermissionsIfNeeded(messaging);
    await _subscribeToNotificationsIfAllowed(settings);
    await _handleNotificationsReceivedWhenAppInBackground(context);
    await _checkForInitialMessage();
  }
}

// Unclear if this is even required, kept here for future reference
Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // PushNotificationSettings.reactToNotification(message);
}