import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_bloc.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_event.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key});

  static Widget withBloc() => MultiBlocProvider(
        providers: [
          BlocProvider<NotificationsBloc>(
              create: (context) => NotificationsBloc(
                    notificationsRepository: RepositoryProvider.of<NotificationRepository>(context),
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  )),
        ],
        child: const NotificationsView(),
      );

  @override
  State createState() {
    return NotificationsViewState();
  }
}

class NotificationsViewState extends State<NotificationsView> {
  late final NotificationsBloc _notificationsBloc;
  late final AuthenticationBloc _authenticationBloc;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = BlocProvider.of<NotificationsBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _notificationsBloc.add(FetchNotifications(user: currentAuthState.authenticatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: BlocBuilder<NotificationsBloc, NotificationsState>(builder: (context, state) {
          if (state is NotificationsLoaded) {
            return Padding(
              padding: const EdgeInsets.all(5),
              child: ListView.builder(
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    return _generateNotificationListItem(state.notifications[index], state.userProfileMap);
                  }),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
        }),
      ),
    );
  }

  Future<void> _pullRefresh() async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _notificationsBloc.add(FetchNotifications(user: currentAuthState.authenticatedUser));
    }
  }

  Widget _generateNotificationListItem(AppNotification notification, Map<String, UserProfile> userProfileMap) {
    switch (notification.notificationType) {
      case "UserFollowRequest":
        return _generateUserFollowRequestNotification(notification, userProfileMap);
      default:
        return const Text("Unknown notification type");
    }
  }

  _goToUserProfile(UserProfile? userProfile) {
    if (userProfile != null) {
      Navigator.pushAndRemoveUntil(context, UserProfileView.route(userProfile), (route) => true);
    }
  }

  Widget _generateUserFollowRequestNotification(AppNotification notification, Map<String, UserProfile> userProfileMap) {
    final String requestingUserId = notification.data['requestingUser'];
    final UserProfile? requestingUserProfile = userProfileMap[requestingUserId];
    if (notification.hasBeenInteractedWith) {
      final didUserApproveFollowRequest = notification.data['didTargetUserApproveFollowRequest'] ?? false;
      final titleText = didUserApproveFollowRequest ?
      "You are now friends with ${_getUserFirstAndLastName(requestingUserProfile)}" :
      "You have rejected ${_getUserFirstAndLastName(requestingUserProfile)}'s request to follow you";
      return ListTile(
        onTap: () async {
          _goToUserProfile(requestingUserProfile);
        },
        leading: GestureDetector(
          onTap: () async {
            _goToUserProfile(requestingUserProfile);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: _getUserProfileImage(requestingUserProfile),
            ),
          ),
        ),
        title: Text(
          titleText,
          style: const TextStyle(fontSize: 15),
        ),
        subtitle: Text(
          DateFormat("hh:mm      yyyy-MM-dd").format(notification.updatedAt),
          style: const TextStyle(fontSize: 10),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _generateActionButton(true),
            const Padding(padding: EdgeInsets.all(5)),
            _generateActionButton(false)
          ],
        ),
      );
    }
    else {
      return ListTile(
        onTap: () async {
          _goToUserProfile(requestingUserProfile);
        },
        leading: GestureDetector(
          onTap: () async {
            _goToUserProfile(requestingUserProfile);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: _getUserProfileImage(requestingUserProfile),
            ),
          ),
        ),
        title: Text(
          "${_getUserFirstAndLastName(requestingUserProfile)} has requested to follow you",
          style: const TextStyle(fontSize: 15),
        ),
        subtitle: Text(
          DateFormat("hh:mm      yyyy-MM-dd").format(notification.updatedAt),
          style: const TextStyle(fontSize: 10),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _generateActionButton(true),
            const Padding(padding: EdgeInsets.all(5)),
            _generateActionButton(false)
          ],
        ),
      );
    }

  }

  String _getUserFirstAndLastName(UserProfile? userProfile) {
    if (userProfile == null) {
      return "A user";
    }
    else {
      return "${userProfile.firstName} ${userProfile.lastName}";
    }
  }


  _generateActionButton(bool isApproveButton) {
    return CircleAvatar(
      radius: 11.5,
      backgroundColor: isApproveButton ? Colors.teal : Colors.redAccent,
      child: Center(
        child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 12,
            onPressed: () {
              print("Yet to do");
            },
            icon: Icon(
              isApproveButton ? Icons.check : Icons.close,
              color: Colors.white,
            )
        ),
      ),
    );
  }

  DecorationImage? _getUserProfileImage(UserProfile? profile) {
    final photoUrlOpt = profile?.photoUrl;
    if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("${ImageUtils.imageBaseUrl}/$photoUrlOpt?transform=100x100"), fit: BoxFit.fitHeight);
    }
    else {
      return null;
    }
  }
}
