import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
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

  Widget _generateNotificationListItem(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    switch (notification.notificationType) {
      case "UserFollowRequest":
        return _generateUserFollowRequestNotification(notification, userProfileMap);
      default:
        return const Text("Unknown notification type");
    }
  }

  _goToUserProfile(PublicUserProfile? userProfile) {
    if (userProfile != null) {
      Navigator.pushAndRemoveUntil(context, UserProfileView.route(userProfile), (route) => true);
    }
  }

  Widget _generateUserFollowRequestNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String requestingUserId = notification.data['requestingUser'];
    final PublicUserProfile? requestingUserProfile = userProfileMap[requestingUserId];
    if (notification.hasBeenInteractedWith) {
      final didUserApproveFollowRequest = notification.data['isApproved'] ?? false;
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
              image: ImageUtils.getUserProfileImage(requestingUserProfile, 100, 100),
            ),
          ),
        ),
        title: Text(
          titleText,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          DateFormat("hh:mm      yyyy-MM-dd").format(notification.updatedAt),
          style: const TextStyle(fontSize: 10),
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
              image: ImageUtils.getUserProfileImage(requestingUserProfile, 100, 100),
            ),
          ),
        ),
        title: Text(
          "${_getUserFirstAndLastName(requestingUserProfile)} has requested to follow you",
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          DateFormat("hh:mm      yyyy-MM-dd").format(notification.updatedAt),
          style: const TextStyle(fontSize: 10),
        ),
        trailing: notification.isInteractive ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _generateActionButton(true, notification, requestingUserId),
            const Padding(padding: EdgeInsets.all(5)),
            _generateActionButton(false, notification, requestingUserId)
          ],
        ) : null,
      );
    }

  }

  String _getUserFirstAndLastName(PublicUserProfile? userProfile) {
    if (userProfile == null) {
      return "A user";
    }
    else {
      return "${userProfile.firstName} ${userProfile.lastName}";
    }
  }


  _generateActionButton(bool isApproveButton, AppNotification notification, String requestingUserId) {
    return CircleAvatar(
      radius: 11.5,
      backgroundColor: isApproveButton ? Colors.teal : Colors.redAccent,
      child: Center(
        child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 12,
            onPressed: () {
              final currentAuthState = _authenticationBloc.state;
              if (notification.isInteractive && currentAuthState is AuthSuccessUserUpdateState) {
                _notificationsBloc.add(
                    NotificationInteractedWith(
                        requestingUserId: requestingUserId,
                        targetUser: currentAuthState.authenticatedUser,
                        notification: notification,
                        isApproved: isApproveButton
                    ));
              }
            },
            icon: Icon(
              isApproveButton ? Icons.check : Icons.close,
              color: Colors.white,
            )
        ),
      ),
    );
  }

}
