import 'dart:io';

import 'package:badges/badges.dart' as badge;
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
import 'package:flutter_app/src/utils/screen_utils.dart';
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
import 'package:flutter_app/src/views/shared_components/ads/bloc/ad_state.dart';
import 'package:flutter_app/src/views/shared_components/ads/custom_ad_widget.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
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
    2: chat,
    3: notifications
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

  void syncFirebaseDeviceRegistrationToken() async {
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

  _reInitWebSockets() {
    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      _menuNavigationBloc.add(ReInitWebSockets(currentUserId: currentState.authenticatedUser.user.id));
    }
    else if (currentState is AuthSuccessState) {
      _menuNavigationBloc.add(ReInitWebSockets(currentUserId: currentState.authenticatedUser.user.id));
    }
  }

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
  }

  _initializeAdsIfNeeded() {
    if (DeviceUtils.isMobileDevice()) {
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
    else {
      // todo - handle web implementation of ads using AdSense
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

  _bottomNavigationBar() {
    final Widget notificationIcon;
    final Widget chatIcon;
    if (unreadNotificationCount != 0) {
      notificationIcon = badge.Badge(
        alignment: Alignment.topRight,
        badgeContent: Text(unreadNotificationCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.notifications),
      );
    }
    else {
      notificationIcon = const Icon(Icons.notifications);
    }

    if (unreadChatRoomCount != 0) {
      chatIcon = badge.Badge(
        alignment: Alignment.topRight,
        badgeContent: Text(unreadChatRoomCount.toString(), style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.chat),
      );
    }
    else {
      chatIcon = const Icon(Icons.chat);
    }

    final maxHeight = ScreenUtils.getScreenHeight(context) / 6;
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    if (adWidget == null) {
      return _bottomNavigationBarInternal(chatIcon, notificationIcon);
    }
    else {
      return SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            _bottomNavigationBarInternal(chatIcon, notificationIcon),
            adWidget,
          ],
        ),
      );
    }
  }

  _bottomNavigationBarInternal(Widget chatIcon, Widget notificationIcon) {
    return BottomNavigationBar(
      unselectedItemColor: Theme.of(context).primaryTextTheme.bodyText2?.color!,
      selectedItemColor: Theme.of(context).primaryColor,
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: 'News Feed',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Discover',
        ),
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
    );
  }

  _drawer() {
    return Drawer(
      child: Column(
        children: [
          _drawerHeader(),
          Expanded(child: _menuDrawerListItems()),
          const Divider(),
          _bottomAlignedButtons(),
        ],
      ),
    );
  }

  _appBar(MenuNavigationState state) {
    if (state is MenuItemSelected) {
      return AppBar(
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
            ListTile(
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
        _generateListTile(friends),
        _generateListTile(meetup),
        _generateListTile(calendar),
        _generateListTile(newsFeed),
        _generateListTile(chat),
        _generateListTile(diary),
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
