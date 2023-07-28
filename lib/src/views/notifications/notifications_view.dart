import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_bloc.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_event.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_state.dart';
import 'package:flutter_app/src/views/selected_post/selected_post_view.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  static const double _scrollThreshold = 200.0;

  final _scrollController = ScrollController();
  bool isDataBeingRequested = false;

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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        final currentAuthState = _authenticationBloc.state;
        if (currentAuthState is AuthSuccessUserUpdateState) {
          isDataBeingRequested = true;
          _notificationsBloc.add(FetchNotifications(user: currentAuthState.authenticatedUser));
        }
      }
    }
  }

  _markNotificationsAsRead(NotificationsLoaded state) {
    WidgetsBinding.instance
        .addPostFrameCallback((_){
      final notificationIds = state.notifications.where((element) => !element.hasBeenViewed).map((e) => e.id).toList();
      if (notificationIds.isNotEmpty) {
        _notificationsBloc.add(
            MarkNotificationsAsRead(
                currentUserId: state.user.user.id,
                notificationIds: notificationIds
            )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: BlocBuilder<NotificationsBloc, NotificationsState>(builder: (context, state) {
          if (state is NotificationsLoaded) {
            isDataBeingRequested = false;
            _markNotificationsAsRead(state);
            if (state.notifications.isEmpty) {
              return const Center(child: Text('No notifications here... come back another time!'));
            }
            else {
              return Padding(
                padding: const EdgeInsets.all(5),
                child: _generateNotificationListView(state),
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

  _generateNotificationListView(NotificationsLoaded state) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
          controller: _scrollController,
          itemCount: state.doesNextPageExist ? state.notifications.length + 1 : state.notifications.length,
          itemBuilder: (context, index) {
            if (index >= state.notifications.length) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return _generateNotificationListItem(state.notifications[index], state.userProfileMap);
            }
          }),
    );
  }

  Future<void> _pullRefresh() async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _notificationsBloc.add(ReFetchNotifications(user: currentAuthState.authenticatedUser));
    }
  }

  Widget _generateNotificationListItem(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    switch (notification.notificationType) {
      case "UserFriendRequest":
        return _generateUserFriendRequestNotification(notification, userProfileMap);

      case "UserCommentedOnPost":
        return _generateUserCommentedOnPostNotification(notification, userProfileMap);

      case "UserLikedPost":
        return _generateUserLikedPostNotification(notification, userProfileMap);

      case "ParticipantAddedToMeetup":
        return _generateParticipantAddedToMeetupNotification(notification, userProfileMap);

      case "ParticipantAddedAvailabilityToMeetup":
        return _generateParticipantAddedAvailabilityToMeetupNotification(notification, userProfileMap);

      case "MeetupDecision":
        return _generateMeetupDecisionNotification(notification, userProfileMap);

      case "MeetupLocationChanged":
        return _generateMeetupLocationChangedNotification(notification, userProfileMap);

      case "UserAttainedNewAchievementMilestone":
        return _generateUserAttainedNewAchievementMilestoneNotification(notification, userProfileMap);

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
      ).then((value) => _pullRefresh());
    }
  }

  _goToSelectedPost(String postId) {
    Navigator.pushAndRemoveUntil(
        context,
        SelectedPostView.route(
            currentUserProfile: widget.currentUserProfile,
            currentPostId: postId,
            isMockDataMode: false
        ),
            (route) => true
    );
  }

  _goToDetailedMeetup(String meetupId) {
    Navigator.pushAndRemoveUntil(
        context,
        DetailedMeetupView.route(meetupId: meetupId, currentUserProfile: widget.currentUserProfile),
            (route) => true
    );
  }

  Widget _generateUserLikedPostNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final List<dynamic> likingUserIdsDynamic = notification.data['likingUsers'];
    final List<String> likingUserIds = likingUserIdsDynamic.map((e) => e as String).toList();
    final String postId = notification.data['postId'];
    final PublicUserProfile? likingUserProfile = userProfileMap[likingUserIds.first];
    return ListTile(
      onTap: () async {
        _goToSelectedPost(postId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(likingUserProfile);
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
        _getLikeNotificationText(likingUserProfile, likingUserIds.length),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  _getLikeNotificationText(
      PublicUserProfile? likingUserProfile,
      int numberOfLikers
      ) {
    if (numberOfLikers == 1) {
      return "${StringUtils.getUserNameFromUserProfile(likingUserProfile)} liked your post";
    }
    else if (numberOfLikers == 2) {
      return "${StringUtils.getUserNameFromUserProfile(likingUserProfile)} and ${numberOfLikers - 1} other person liked your post";
    }
    else {
      return "${StringUtils.getUserNameFromUserProfile(likingUserProfile)} and ${numberOfLikers - 1} others liked your post";
    }
  }

  // Default to current user in case not available, to maintain backwards compatibility
  String _getPostCreatorId(AppNotification notification) {
    try {
      final id = notification.data['postCreatorId'];
      return id;
    } catch (e) {
      return widget.currentUserProfile.userId;
    }
  }

  Widget _generateUserCommentedOnPostNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final List<dynamic> commentingUserIdsDynamic = notification.data['commentingUsers'];
    final List<String> commentingUserIds = commentingUserIdsDynamic.map((e) => e as String).toList();
    final String postId = notification.data['postId'];
    final String postCreatorId = _getPostCreatorId(notification);
    final PublicUserProfile? commentingUserProfile = userProfileMap[commentingUserIds.first];
    final PublicUserProfile? staticDeletedUserProfile = userProfileMap[ConstantUtils.staticDeletedUserId];
    final PublicUserProfile postCreatorUserProfile = userProfileMap[postCreatorId] ?? widget.currentUserProfile;
    return ListTile(
      onTap: () async {
        _goToSelectedPost(postId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(commentingUserProfile);
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
        _getCommentNotificationText(commentingUserProfile ?? staticDeletedUserProfile!, postCreatorUserProfile, commentingUserIds.length),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _generateParticipantAddedAvailabilityToMeetupNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String meetupId = notification.data['meetupId'];
    final String participantId = notification.data['participantId'];
    final String meetupName =  notification.data['meetupName'] ?? "";

    final PublicUserProfile? participantWhoAddedAvailabilityProfile = userProfileMap[participantId];
    final PublicUserProfile? staticDeletedUserProfile = userProfileMap[ConstantUtils.staticDeletedUserId];
    return ListTile(
      onTap: () async {
        _goToDetailedMeetup(meetupId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(participantWhoAddedAvailabilityProfile);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(participantWhoAddedAvailabilityProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        _getParticipantAddedAvailabilityToMeetupNotificationText(
            participantWhoAddedAvailabilityProfile ?? staticDeletedUserProfile!,
            meetupName
        ),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _generateParticipantAddedToMeetupNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String meetupId = notification.data['meetupId'];
    final String meetupOwnerId = notification.data['meetupOwnerId'];
    final String participantId = notification.data['participantId'];
    final String meetupName =  notification.data['meetupName'] ?? "";

    final PublicUserProfile? meetupOwnerProfile = userProfileMap[meetupOwnerId];
    final PublicUserProfile? staticDeletedUserProfile = userProfileMap[ConstantUtils.staticDeletedUserId];
    return ListTile(
      onTap: () async {
        _goToDetailedMeetup(meetupId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(meetupOwnerProfile);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(meetupOwnerProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        _getParticipantAddedToMeetupNotificationText(meetupOwnerProfile ?? staticDeletedUserProfile!, meetupName),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _generateUserAttainedNewAchievementMilestoneNotification(
      AppNotification notification,
      Map<String, PublicUserProfile> userProfileMap
      ) {

    final String milestoneName = notification.data['milestoneName'];
    final String milestoneCategory = notification.data['milestoneCategory'];
    final int attainedAtInMillis = notification.data['attainedAtInMillis'];

    return ListTile(
      onTap: () async {
        // _goToDetailedMeetup(meetupId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(widget.currentUserProfile);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        "You have achieved a milestone in the $milestoneCategory category! Congrats on reaching $milestoneName!",
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _generateMeetupLocationChangedNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String meetupId = notification.data['meetupId'];
    final String participantId = notification.data['targetUserId'];
    final String meetupOwnerId = notification.data['meetupOwnerId'];
    final String meetupName = notification.data['meetupName'] ?? "";

    final PublicUserProfile? meetupOwnerProfile = userProfileMap[meetupOwnerId];
    final PublicUserProfile? staticDeletedUserProfile = userProfileMap[ConstantUtils.staticDeletedUserId];
    return ListTile(
      onTap: () async {
        _goToDetailedMeetup(meetupId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(meetupOwnerProfile);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(meetupOwnerProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        _getMeetupLocationChangedNotificationText(meetupOwnerProfile ?? staticDeletedUserProfile!, meetupName),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _generateMeetupDecisionNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String meetupId = notification.data['meetupId'];
    final String participantId = notification.data['participantId'];
    final bool hasAccepted = notification.data['hasAccepted'];
    final String meetupName = notification.data['meetupName'] ?? "";

    final PublicUserProfile? participantProfile = userProfileMap[participantId];
    final PublicUserProfile? staticDeletedUserProfile = userProfileMap[ConstantUtils.staticDeletedUserId];
    return ListTile(
      onTap: () async {
        _goToDetailedMeetup(meetupId);
      },
      tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
      leading: GestureDetector(
        onTap: () async {
          _goToUserProfile(participantProfile);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(participantProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        _getMeetupDecisionNotificationText(participantProfile ?? staticDeletedUserProfile!, hasAccepted, meetupName),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Text(
          timeago.format(notification.updatedAt.toLocal()),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  _getParticipantAddedToMeetupNotificationText(PublicUserProfile meetupOwnerProfile, String meetupName) {
    if (meetupName.isNotEmpty) {
      return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} added you to a meetup: $meetupName";
    }
    else {
      return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} added you to a meetup";
    }
  }

  _getParticipantAddedAvailabilityToMeetupNotificationText(PublicUserProfile participantProfile, String meetupName) {
    if (meetupName.isNotEmpty) {
      return "${StringUtils.getUserNameFromUserProfile(participantProfile)} added their availability to a meetup: $meetupName";
    }
    else {
      return "${StringUtils.getUserNameFromUserProfile(participantProfile)} added their availability to a meetup";
    }
  }

  _getMeetupLocationChangedNotificationText(PublicUserProfile meetupOwnerProfile, String meetupName) {
    if (meetupName.isNotEmpty) {
      return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} changed the location of the meetup: $meetupName";
    }
    else {
      return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} changed the location of a meetup";
    }
  }

  _getMeetupDecisionNotificationText(PublicUserProfile meetupOwnerProfile, bool hasAccepted, String meetupName) {
    if (hasAccepted) {
      if (meetupName.isNotEmpty) {
        return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} has accepted your meetup invite: $meetupName";
      }
      else {
        return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} has accepted your meetup invite";
      }
    }
    else {
      if (meetupName.isNotEmpty) {
        return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} has declined your meetup invite: $meetupName";
      }
      else {
        return "${StringUtils.getUserNameFromUserProfile(meetupOwnerProfile)} has declined your meetup invite";
      }
    }
  }

  _getCommentNotificationText(
      PublicUserProfile commentingUserProfile,
      PublicUserProfile postCreatorUserProfile,
      int numberOfLikers
  ) {
    if (numberOfLikers == 1) {
      if (postCreatorUserProfile.userId == widget.currentUserProfile.userId) {
        return "${StringUtils.getUserNameFromUserProfile(commentingUserProfile)} commented on your post";
      }
      else {
        return "${StringUtils.getUserNameFromUserProfile(commentingUserProfile)} commented on ${StringUtils.getUserNameFromUserProfile(postCreatorUserProfile)}'s post";
      }
    }
    else if (numberOfLikers == 2) {
      if (postCreatorUserProfile.userId == widget.currentUserProfile.userId) {
        return "${StringUtils.getUserNameFromUserProfile(commentingUserProfile)} and 1 other person commented on your post";
      }
      else {
        return "${StringUtils.getUserNameFromUserProfile(commentingUserProfile)} and 1 other person commented on ${StringUtils.getUserNameFromUserProfile(postCreatorUserProfile)}'s post";
      }
    }
    else {
      if (postCreatorUserProfile.userId == widget.currentUserProfile.userId) {
        return "${StringUtils.getUserNameFromUserProfile(commentingUserProfile)} and ${numberOfLikers - 1} others commented on your post";
      }
      else {
        return "${StringUtils.getUserNameFromUserProfile(commentingUserProfile)} and ${numberOfLikers - 1} others commented on ${StringUtils.getUserNameFromUserProfile(postCreatorUserProfile)}'s post";
      }
    }
  }

  Widget _generateUserFriendRequestNotification(AppNotification notification, Map<String, PublicUserProfile> userProfileMap) {
    final String requestingUserId = notification.data['requestingUser'];
    final PublicUserProfile? requestingUserProfile = userProfileMap[requestingUserId];
    if (notification.hasBeenInteractedWith) {
      final didUserApproveFollowRequest = notification.data['isApproved'] ?? false;
      final titleText = didUserApproveFollowRequest ?
      "${StringUtils.getUserNameFromUserProfile(requestingUserProfile)} is now friends with you" :
      "You have rejected ${StringUtils.getUserNameFromUserProfile(requestingUserProfile)}'s friend request";
      return ListTile(
        onTap: () async {
          _goToUserProfile(requestingUserProfile);
        },
        tileColor: notification.hasBeenViewed ? null : Theme.of(context).highlightColor,
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
        subtitle: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: Text(
            timeago.format(notification.updatedAt.toLocal()),
            style: const TextStyle(fontSize: 10),
          ),
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
          "${StringUtils.getUserNameFromUserProfile(requestingUserProfile)} has sent you a friend request",
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: Text(
            timeago.format(notification.updatedAt.toLocal()),
            style: const TextStyle(fontSize: 10),
          ),
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
