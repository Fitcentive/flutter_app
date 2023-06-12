import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart' as badge;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/firebase/firebase_options.dart';
import 'package:flutter_app/src/infrastructure/firebase/push_notification_settings.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/chat_room_updated_stream_repository.dart';
import 'package:flutter_app/src/models/device/local_device_info.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/push/notification_device.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/calendar/calendar_view.dart';
import 'package:flutter_app/src/views/chat_home/chat_home_view.dart';
import 'package:flutter_app/src/views/diary/diary_view.dart';
import 'package:flutter_app/src/views/discover_home/discover_home_view.dart';
import 'package:flutter_app/src/views/meetup_home/meetup_home_view.dart';
import 'package:flutter_app/src/views/newsfeed/newsfeed_view.dart';
import 'package:flutter_app/src/views/account_details/account_details_view.dart';
import 'package:flutter_app/src/views/friends/friends_view.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_bloc.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/notifications/notifications_view.dart';
import 'package:flutter_app/src/views/search/search_view.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_bloc.dart';
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_event.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

GlobalKey bottomBarKey = GlobalKey();
GlobalKey newsFeedButtonKey = GlobalKey();
GlobalKey meetupButtonKey = GlobalKey();
GlobalKey diaryButtonKey = GlobalKey();
GlobalKey chatButtonKey = GlobalKey();
GlobalKey notificationsButtonKey = GlobalKey();
GlobalKey discoverButtonKey = GlobalKey();
GlobalKey appDrawerKey = GlobalKey();
GlobalKey accountDetailsKey = GlobalKey();
GlobalKey searchKey = GlobalKey();
GlobalKey friendsKey = GlobalKey();
GlobalKey calendarKey = GlobalKey();

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
                userRepository: RepositoryProvider.of<UserRepository>(context) ,
                notificationRepository: RepositoryProvider.of<NotificationRepository>(context),
                secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                chatRoomUpdatedStreamRepository: RepositoryProvider.of<ChatRoomUpdatedStreamRepository>(context),
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

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool hasFirebaseTokenBeenSynced = false;

  static const String accountDetails = 'Account Details';
  static const String notifications = 'Notifications';
  static const String discover = 'Discover';
  static const String search = 'Search';
  static const String friends = 'Friends';
  static const String calendar = 'Calendar';
  static const String newsFeed = 'News Feed';
  static const String meetup = 'Meetup';
  static const String chat = 'Chat';
  static const String logout = 'Logout';
  static const String diary = 'Diary';

  static const bottomBarToAppDrawerItemMap = {
    0: newsFeed,
    1: discover,
    2: meetup,
    3: diary,
    // 5: calendar,
    4: chat,
    5: notifications,
  };

  final logger = Logger("HomePageState");

  late String selectedMenuItem;
  late int unreadNotificationCount;
  late int unreadChatRoomCount;

  int selectedBottomBarIndex = 0;

  UserProfile? userProfile;

  late AuthenticationBloc _authenticationBloc;
  late MenuNavigationBloc _menuNavigationBloc;
  late AdBloc _adBloc;

  late NotificationRepository _notificationRepository;
  late FlutterSecureStorage _secureStorage;

  List<TargetFocus> basicTargets = [];
  TutorialCoachMark? basicTutorialCoachMark;

  List<TargetFocus> appDrawerTargets = [];
  TutorialCoachMark? appDrawerTutorialCoachMark;
  bool hasAppDrawerTutorialBeenShown = false;
  bool hasBasicTutorialBeenShown = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch(state) {
      case AppLifecycleState.resumed:
        _reInitWebSockets();
        break;
      case AppLifecycleState.inactive:
      // Handle this case
        break;
      case AppLifecycleState.paused:
      // Handle this case
        break;
      default:
        break;
    }


  }

  @override
  void dispose() {
    _menuNavigationBloc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _menuNavigationBloc = BlocProvider.of<MenuNavigationBloc>(context);
    _adBloc = BlocProvider.of<AdBloc>(context);

    _notificationRepository = RepositoryProvider.of<NotificationRepository>(context);
    _secureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);

    selectedMenuItem = widget.defaultSelectedTab;
    unreadNotificationCount = 0;
    unreadChatRoomCount = 0;

    _updateBloc(selectedMenuItem);

    PushNotificationSettings.setupFirebasePushNotifications(context, FirebaseMessaging.instance);
    _initializeAdsIfNeeded();

    _showBasicTutorialIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthSuccessUserUpdateState) {
          userProfile = state.authenticatedUser.userProfile;
          syncFirebaseDeviceRegistrationToken();
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          return BlocBuilder<MenuNavigationBloc, MenuNavigationState>(
              builder: (BuildContext context, MenuNavigationState state) {
                if (state is MenuItemSelected) {
                  selectedMenuItem = state.selectedMenuItem;
                  unreadNotificationCount = state.unreadNotificationCount;
                  unreadChatRoomCount = state.unreadChatRoomIds.length;
                  _updateAppBadgeIfPossible();
                }
                return Scaffold(
                  appBar: _appBar(state),
                  drawer: _drawer(),
                  body: _generateBody(selectedMenuItem),
                  bottomNavigationBar: _bottomNavigationBar(),
                );
              });
        },
      ),
    );
  }

  void createTutorial() {
    createBasicTutorialTargets();

    basicTutorialCoachMark = TutorialCoachMark(
      targets: basicTargets,
      colorShadow: Colors.teal,
      textSkip: "SKIP",
      showSkipInLastTarget: false,
      focusAnimationDuration: const Duration(milliseconds: 200),
      unFocusAnimationDuration: const Duration(milliseconds: 200),
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {},
      onClickTarget: (target) {},
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
      onSkip: () {},
    );
  }

  void createAppDrawerTutorialIfNeeded() {
    if (appDrawerTargets.isEmpty) {
      // Account details
      appDrawerTargets.add(
        TargetFocus(
          identify: "accountDetailsKey",
          keyTarget: accountDetailsKey,
          alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
          color: Colors.teal,
          shape: ShapeLightFocus.RRect,
          enableOverlayTab: true,
          enableTargetTab: true,
          paddingFocus: 10,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: Text(
                        "This is your profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    WidgetUtils.spacer(10),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: AutoSizeText(
                        "You can update your account details here!",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

      // Search
      appDrawerTargets.add(
        TargetFocus(
          identify: "searchKey",
          keyTarget: searchKey,
          alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
          color: Colors.teal,
          shape: ShapeLightFocus.RRect,
          enableOverlayTab: true,
          enableTargetTab: true,
          paddingFocus: 10,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: Text(
                        "Search for users and activities",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    WidgetUtils.spacer(10),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: AutoSizeText(
                        "Make new friends and discover activities to log!",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

      // Friends
      appDrawerTargets.add(
        TargetFocus(
          identify: "friendsKey",
          keyTarget: friendsKey,
          alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
          color: Colors.teal,
          shape: ShapeLightFocus.RRect,
          enableOverlayTab: true,
          enableTargetTab: true,
          paddingFocus: 10,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: Text(
                        "These are your friends",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    WidgetUtils.spacer(10),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: AutoSizeText(
                        "View and manage your friends here!",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

      // Calendar
      appDrawerTargets.add(
        TargetFocus(
          identify: "calendarKey",
          keyTarget: calendarKey,
          alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
          color: Colors.teal,
          shape: ShapeLightFocus.RRect,
          enableOverlayTab: true,
          enableTargetTab: true,
          paddingFocus: 10,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: Text(
                        "This is your calendar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    WidgetUtils.spacer(10),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: AutoSizeText(
                        "View scheduled meetups and never miss an event!",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    appDrawerTutorialCoachMark ??= TutorialCoachMark(
        targets: appDrawerTargets,
        colorShadow: Colors.teal,
        textSkip: "SKIP",
        showSkipInLastTarget: false,
        focusAnimationDuration: const Duration(milliseconds: 200),
        unFocusAnimationDuration: const Duration(milliseconds: 200),
        paddingFocus: 10,
        opacityShadow: 0.8,
        onFinish: () {},
        onClickTarget: (target) {},
        onClickTargetWithTapPosition: (target, tapDetails) {},
        onClickOverlay: (target) {},
        onSkip: () {},
      );

  }

  void createBasicTutorialTargets() {
    // Welcome target
    basicTargets.add(
      TargetFocus(
        identify: "welcomeTargetKey",
        keyTarget: bottomBarKey,
        alignSkip: Alignment.centerRight,
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "Let's get you started",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "This short tour will provide you with a brief introduction",
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Bottom drawer target
    basicTargets.add(
      TargetFocus(
        identify: "bottomBarKey",
        keyTarget: bottomBarKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "This is your quick access menu",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Find your most frequently accessed pages here!",
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Newsfeed target
    basicTargets.add(
      TargetFocus(
        identify: "newsFeedButtonKey",
        keyTarget: newsFeedButtonKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "This is your social feed",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Explore what's happening in your community over here!",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Discover target
    basicTargets.add(
      TargetFocus(
        identify: "discoverButtonKey",
        keyTarget: discoverButtonKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "This is your discover page",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Discover users with similar goals and interests!",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Meetup target
    basicTargets.add(
      TargetFocus(
        identify: "meetupButtonKey",
        keyTarget: meetupButtonKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "This is your meetup page",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Make plans with discovered users!",
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Diary target
    basicTargets.add(
      TargetFocus(
        identify: "diaryButtonKey",
        keyTarget: diaryButtonKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "This is your diary",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Log your nutrition and track your daily activities!",
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Chat target
    basicTargets.add(
      TargetFocus(
        identify: "chatButtonKey",
        keyTarget: chatButtonKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "These are your conversations",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Chat with discovered users!",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Notification target
    basicTargets.add(
      TargetFocus(
        identify: "notificationsButtonKey",
        keyTarget: notificationsButtonKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "These are your notifications",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Be notified of your interactions with others!",
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // App drawer target
    basicTargets.add(
      TargetFocus(
        identify: "appDrawerKey",
        keyTarget: appDrawerKey,
        alignSkip: Alignment.lerp(Alignment.bottomRight, Alignment.centerRight, 0.5),
        color: Colors.teal,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        enableTargetTab: true,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Text(
                      "Explore more pages over here",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  WidgetUtils.spacer(10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: AutoSizeText(
                      "Manage your account, view your calendar, and so much more!",
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );


  }

  _showBasicTutorialIfNeeded() {
    _createTutorialAndMarkAsComplete(String userId) {
      WidgetsBinding.instance
          .addPostFrameCallback((_){
        createTutorial();
        if (!hasBasicTutorialBeenShown) {
          basicTutorialCoachMark?.show(context: context);
          // Show tutorial here
          _markUserAppTutorialAsComplete(userId);
        }
      });
    }

    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      if (!(currentState.authenticatedUser.userTutorialStatus?.isTutorialComplete ?? false)) {
        _createTutorialAndMarkAsComplete(currentState.authenticatedUser.user.id);
      }
    }
    else if (currentState is AuthSuccessState) {
      if (!(currentState.authenticatedUser.userTutorialStatus?.isTutorialComplete ?? false)) {
        _createTutorialAndMarkAsComplete(currentState.authenticatedUser.user.id);
      }
    }
  }

  _showAppDrawerTutorialIfNeeded() {
    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      if (!(currentState.authenticatedUser.userTutorialStatus?.isTutorialComplete ?? false)) {
        if (!hasAppDrawerTutorialBeenShown) {
          hasAppDrawerTutorialBeenShown = true;
          appDrawerTutorialCoachMark?.show(context: context);
        }
      }
    }
    else if (currentState is AuthSuccessState) {
      if (!(currentState.authenticatedUser.userTutorialStatus?.isTutorialComplete ?? false)) {
        if (!hasAppDrawerTutorialBeenShown) {
          hasAppDrawerTutorialBeenShown = true;
          appDrawerTutorialCoachMark?.show(context: context);
        }
      }
    }
  }

  _markUserAppTutorialAsComplete(String currentUserId) {
    _menuNavigationBloc.add(MarkUserAppTutorialAsComplete(currentUserId: currentUserId));
  }

  _initializeAdsIfNeeded() {
    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      if (authState.authenticatedUser.user.isPremiumEnabled) {
        _adBloc.add(const NoAdsRequiredAsUserIsPremium());
      }
      else {
        _adBloc.add(const FetchAdUnitIds());
      }
    }
    else if (authState is AuthSuccessState) {
      if (authState.authenticatedUser.user.isPremiumEnabled) {
        _adBloc.add(const NoAdsRequiredAsUserIsPremium());
      }
      else {
        _adBloc.add(const FetchAdUnitIds());
      }
    }
  }

  _updateAppBadgeIfPossible() async {
    if (DeviceUtils.isMobileDevice()) {
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (isSupported) {
        FlutterAppBadger.updateBadgeCount(unreadNotificationCount);
      }
    }
  }

  void syncFirebaseDeviceRegistrationToken() async {
    if (!hasFirebaseTokenBeenSynced) {
      hasFirebaseTokenBeenSynced = true;
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
              LocalDeviceInfo(
                  manufacturer: "Apple",
                  model: iosInfo.model!,
                  isPhysicalDevice: iosInfo.isPhysicalDevice
              );
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
          _syncTokenWithServer(token, localDeviceInfo);
        });
        String? token = await FirebaseMessaging.instance.getToken(vapidKey: DefaultFirebaseOptions.vapidKey);
        _syncTokenWithServer(token!, localDeviceInfo);
      }
    }
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

  _reInitWebSockets() {
    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      _menuNavigationBloc.add(ReInitWebSockets(currentUserId: currentState.authenticatedUser.user.id));
    }
    else if (currentState is AuthSuccessState) {
      _menuNavigationBloc.add(ReInitWebSockets(currentUserId: currentState.authenticatedUser.user.id));
    }
  }

  _bottomNavigationBar() {
    final Widget notificationIcon;
    final Widget chatIcon;
    if (unreadNotificationCount != 0) {
      notificationIcon = badge.Badge(
        alignment: Alignment.topRight,
        badgeContent: Text(unreadNotificationCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.notifications,
          key: notificationsButtonKey,
        ),
      );
    }
    else {
      notificationIcon = Icon(
        Icons.notifications,
        key: notificationsButtonKey,
      );
    }

    if (unreadChatRoomCount != 0) {
      chatIcon = badge.Badge(
        alignment: Alignment.topRight,
        badgeContent: Text(unreadChatRoomCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.chat,
          key: chatButtonKey,
        ),
      );
    }
    else {
      chatIcon = Icon(
        Icons.chat,
        key: chatButtonKey,
      );
    }

    final double maxHeight = AdUtils.defaultBannerAdHeight(context) * 2;
    final Widget? adWidget = WidgetUtils.showHomePageAdIfNeeded(context, maxHeight);
    if (adWidget == null) {
      return _bottomNavigationBarInternal(chatIcon, notificationIcon, maxHeight/2);
    }
    else {
      return IntrinsicHeight(
        child: Column(
          children: [
            _bottomNavigationBarInternal(chatIcon, notificationIcon, maxHeight),
            adWidget,
          ],
        ),
      );
    }
  }

  _bottomNavigationBarInternal(Widget chatIcon, Widget notificationIcon, double maxHeight) {
    return IntrinsicHeight(
      child: Column(
        children: WidgetUtils.skipNulls([
          WidgetUtils.showUpgradeToMobileAppMessageIfNeeded(),
          BottomNavigationBar(
            key: bottomBarKey,
            unselectedItemColor: Theme.of(context).primaryTextTheme.bodyText2?.color!,
            selectedItemColor: Theme.of(context).primaryColor,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.newspaper,
                  key: newsFeedButtonKey,
                ),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.explore,
                  key: discoverButtonKey,
                ),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.location_on,
                  key: meetupButtonKey,
                ),
                label: 'Meetup',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.menu_book,
                  key: diaryButtonKey,
                ),
                label: 'Diary',
              ),
              // const BottomNavigationBarItem(
              //   icon: Icon(Icons.calendar_month),
              //   label: 'Calendar',
              // ),
              BottomNavigationBarItem(
                icon: chatIcon,
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: notificationIcon,
                label: 'Notifications',
              ),
            ],
            currentIndex: selectedBottomBarIndex,
            onTap: (selectedItemIndex) {
              if (selectedItemIndex != selectedBottomBarIndex) {
                final currentState = _authenticationBloc.state;
                if (currentState is AuthSuccessUserUpdateState) {
                  _menuNavigationBloc.add(
                      MenuItemChosen(
                          selectedMenuItem: bottomBarToAppDrawerItemMap[selectedItemIndex]!,
                          currentUserId: currentState.authenticatedUser.user.id
                      )
                  );
                  setState(() {
                    selectedBottomBarIndex = selectedItemIndex;
                  });
                }
              }
            },
          ),
        ]),
      ),
    );
  }

  _drawer() {
    return PointerInterceptor(
      child: Drawer(
        elevation: 1,
        child: Column(
          children: [
            _drawerHeader(),
            Expanded(child: _menuDrawerListItems()),
            const Divider(),
            _bottomAlignedButtons(),
          ],
        ),
      ),
    );
  }

  _appBar(MenuNavigationState state) {
    if (state is MenuItemSelected) {
      return AppBar(
        leading: Builder(
          key: appDrawerKey,
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.teal,),
              onPressed: () {
                Scaffold.of(context).openDrawer();
                // We wait to ensure drawer is open and elements are in scope
                Future.delayed(const Duration(milliseconds: 250), () {
                createAppDrawerTutorialIfNeeded();
                _showAppDrawerTutorialIfNeeded();
                });
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        title: Text(selectedMenuItem, style: const TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(color: Colors.teal),
        actions: state.selectedMenuItem == diary ? [
          IconButton(
            icon: const Icon(
              Icons.person,
              color: Colors.teal,
            ),
            onPressed: () {
              _diaryScreenAppBarButtonPressed();
            },
          )
        ] : [
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
      );
    }
  }

  _diaryScreenAppBarButtonPressed() {
    diaryViewStateGlobalKey.currentState?.goToUserFitnessProfileView();
  }

  Widget _bottomAlignedButtons() {
    return Align(
        alignment: FractionalOffset.bottomCenter,
        // This container holds all the children that will be aligned
        // on the bottom and should not scroll with the above ListView
        child: Column(
          children: <Widget>[
            Material(
              elevation: 1,
              child: ListTile(
                title: const Text("Logout"),
                onTap: () {
                  showDialog(context: context, builder: (context) {
                    Widget cancelButton = TextButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                      ),
                      onPressed:  () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    );
                    Widget continueButton = TextButton(
                      onPressed:  () {
                        Navigator.pop(context);
                        _signOutIfApplicable();
                      },
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                      ),
                      child: const Text("Logout"),
                    );

                    return AlertDialog(
                      title: const Text("You are about to log out of your account!"),
                      content: const Text("Are you sure?"),
                      actions: [
                        cancelButton,
                        continueButton,
                      ],
                    );
                  });
                },
              ),
            )
          ],
        )
    );
  }

  Widget _drawerHeader() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(builder: (context, state) {
      return SizedBox(
        key: accountDetailsKey,
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

    void updateBlocInternal(String currentUserId) {
      _menuNavigationBloc.add(
          MenuItemChosen(
              selectedMenuItem: selectedItem  ,
              currentUserId: currentUserId
          )
      );
      if (bottomBarToAppDrawerItemMap.values.contains(selectedItem)) {
        setState(() {
          selectedBottomBarIndex =
              bottomBarToAppDrawerItemMap.keys.firstWhere((k) => bottomBarToAppDrawerItemMap[k] == selectedItem);
        });
      }
    }

    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      updateBlocInternal(currentState.authenticatedUser.user.id);
    }
    else if (currentState is AuthSuccessState) {
      updateBlocInternal(currentState.authenticatedUser.user.id);
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
      return ImageUtils.getImage(state.authenticatedUser.userProfile?.photoUrl, 100, 100);
    } else {
      return null;
    }
  }

  Widget _generateListTile(String text, Key key) {
    final Widget element;
    if (text == notifications && unreadNotificationCount != 0) {
      element =  badge.Badge(
        alignment: Alignment.centerLeft,
        badgeContent: Text(unreadNotificationCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(10),
        child: Text(text),
      );
    }
    else if (text == chat && unreadChatRoomCount != 0) {
      element =  badge.Badge(
        alignment: Alignment.centerLeft,
        badgeContent: Text(unreadChatRoomCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(10),
        child: Text(text),
      );
    }
    else {
      element = Text(text);
    }
    return ListTile(
      key: key,
      title: element,
      onTap: () {
        Navigator.pop(context);
        if (selectedMenuItem != text) {
          _updateBloc(text);
        }
      },
    );
  }

  // We only show those menu list items that do not appear in the bottom bar
  Widget _menuDrawerListItems() {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: <Widget>[
        // _generateListTile(notifications),
        _generateListTile(search, searchKey),
        // _generateListTile(discover),
        // _generateListTile(meetup),
        // _generateListTile(diary),
        _generateListTile(friends, friendsKey),
        // _generateListTile(chat),
        _generateListTile(calendar, calendarKey),
        // _generateListTile(newsFeed),
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
          return AccountDetailsView.withBloc(publicUserProfile, authState.authenticatedUser);
        case "Notifications":
          return NotificationsView.withBloc(publicUserProfile);
        case "Search":
          return SearchView.withBloc(publicUserProfile);
        case "Friends":
          return FriendsView.withBloc(publicUserProfile);
        case "News Feed":
          return NewsFeedView.withBloc(publicUserProfile);
        case "Chat":
          return ChatHomeView.withBloc(publicUserProfile);
        case "Discover":
          return DiscoverHomeView.withBloc(publicUserProfile);
        case "Meetup":
          return MeetupHomeView.withBloc(publicUserProfile);
        case "Calendar":
          return CalendarView.withBloc(publicUserProfile);
        case "Diary":
          return DiaryView.withBloc(diaryViewStateGlobalKey, publicUserProfile);
        default:
          return _oldStuff();
      }
    }
    else if (authState is AccountDeletionInProgressState) {
      return _accountDeletionInProgressView();
    }
    else {
      return const Center(
        child: Text("Bad State"),
      );
    }
  }

  _accountDeletionInProgressView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            WidgetUtils.spacer(10),
            const Text("Please wait, your account is being deleted....", textAlign: TextAlign.center,),
            WidgetUtils.spacer(5),
            const Text("You will be logged out once this operation is completed", textAlign: TextAlign.center,),
          ],
        ),
      ),
    );
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
