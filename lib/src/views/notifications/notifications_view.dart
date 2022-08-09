import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_bloc.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_event.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_state.dart';
import 'package:flutter_app/src/views/selected_post/selected_post_view.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class NotificationsView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const NotificationsView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
        providers: [
          BlocProvider<NotificationsBloc>(
              create: (context) => NotificationsBloc(
                    notificationsRepository: RepositoryProvider.of<NotificationRepository>(context),
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  )),
        ],
        child: NotificationsView(currentUserProfile: currentUserProfile),
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
            if (state.notifications.isEmpty) {
              return const Center(child: Text('No Results'));
            }
            else {
              return Padding(
                padding: const EdgeInsets.all(5),
                child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      return _generateNotificationListItem(state.notifications[index], state.userProfileMap);
                    }),
              );
            }
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
      case "UserCommentedOnPost":
        return _generateUserCommentedOnPostNotification(notification, userProfileMap);
      case "UserLikedPost":
        return _generateUserLikedPostNotification(notification, userProfileMap);
      default:
        return const Text("Unknown notification type");
    }
  }

  _goToUserProfile(PublicUserProfile? userProfile) {
    if (userProfile != null) {
      Navigator.pushAndRemoveUntil(
          context,
          UserProfileView.route(userProfile, widget.currentUserProfile),
              (route) => true
      );
    }
  }

  _goToSelectedPost(String postId) {
    Navigator.pushAndRemoveUntil(
        context,
        SelectedPostView.route(widget.currentUserProfile, postId),
            (route) => true
    );
  }

  Widget _generateUserLikedPostNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String requestingUserId = notification.data['likingUser'];
    final String postId = notification.data['postId'];
    final PublicUserProfile? likingUserProfile = userProfileMap[requestingUserId];
    return ListTile(
      onTap: () async {
        _goToSelectedPost(postId);
      },
      leading: GestureDetector(
        onTap: () async {
          _goToSelectedPost(postId);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(likingUserProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        "${_getUserFirstAndLastName(likingUserProfile)} liked your post",
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        DateFormat("hh:mm a     yyyy-MM-dd").format(notification.updatedAt.add(DateTime.now().timeZoneOffset)),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _generateUserCommentedOnPostNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String requestingUserId = notification.data['commentingUser'];
    final String postId = notification.data['postId'];
    final PublicUserProfile? commentingUserProfile = userProfileMap[requestingUserId];
    return ListTile(
      onTap: () async {
        _goToSelectedPost(postId);
      },
      leading: GestureDetector(
        onTap: () async {
          _goToSelectedPost(postId);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(commentingUserProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        "${_getUserFirstAndLastName(commentingUserProfile)} commented on your post",
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        DateFormat("hh:mm a     yyyy-MM-dd").format(notification.updatedAt.add(DateTime.now().timeZoneOffset)),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _generateUserFollowRequestNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String requestingUserId = notification.data['requestingUser'];
    final PublicUserProfile? requestingUserProfile = userProfileMap[requestingUserId];
    if (notification.hasBeenInteractedWith) {
      final didUserApproveFollowRequest = notification.data['isApproved'] ?? false;
      final titleText = didUserApproveFollowRequest ?
      "${_getUserFirstAndLastName(requestingUserProfile)} is now following you" :
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
          DateFormat("hh:mm a     yyyy-MM-dd").format(notification.updatedAt.add(DateTime.now().timeZoneOffset)),
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
          DateFormat("hh:mm a      yyyy-MM-dd").format(notification.updatedAt.add(DateTime.now().timeZoneOffset)),
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
      radius: 9.5,
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
                    )
                );
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
