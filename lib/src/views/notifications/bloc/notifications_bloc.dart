import 'dart:convert';

import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_event.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository notificationsRepository;
  final UserRepository userRepository;
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  NotificationsBloc({
    required this.notificationsRepository,
    required this.userRepository,
    required this.socialMediaRepository,
    required this.secureStorage,
  }) : super(const NotificationsInitial()) {
    on<FetchNotifications>(_fetchNotifications);
    on<NotificationInteractedWith>(_notificationInteractedWith);
    on<MarkNotificationsAsRead>(_markNotificationsAsRead);
  }

  void _markNotificationsAsRead(MarkNotificationsAsRead event, Emitter<NotificationsState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await notificationsRepository.markNotificationsAsRead(event.currentUserId, event.notificationIds, accessToken!);
  }

  void _notificationInteractedWith(NotificationInteractedWith event, Emitter<NotificationsState> emit) async {
    if (event.notification.isInteractive && event.notification.notificationType == "UserFollowRequest") {
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final newNotifications = currentState.notifications.map((n) {
          if (n.id == event.notification.id) {
            final now = DateTime.now().toUtc();
            final jsonBody = {
              ...n.data,
              'isApproved': event.isApproved,
            };
            return AppNotification(
                id: n.id,
                targetUser: n.targetUser,
                notificationType: n.notificationType,
                isInteractive: n.isInteractive,
                hasBeenInteractedWith: true,
                hasBeenViewed: true,
                data: jsonBody,
                createdAt: n.createdAt,
                updatedAt: now
            );
          }
          else {
            return n;
          }
        }).toList();
        emit(const NotificationsLoading());
        emit(NotificationsLoaded(
            notifications: newNotifications,
            user: currentState.user,
            userProfileMap: currentState.userProfileMap
        ));
      }

      final accessToken = await secureStorage.read(key: event.targetUser.authTokens.accessTokenSecureStorageKey);
      await socialMediaRepository.applyUserDecisionToFollowRequest(
          event.requestingUserId,
          event.targetUser.user.id,
          event.isApproved,
          accessToken!
      );
      await notificationsRepository
          .updateUserNotification(event.targetUser.user.id, event.notification, event.isApproved, accessToken);
    }
  }

  void _fetchNotifications(FetchNotifications event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading());
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final List<AppNotification> notifications =
        await notificationsRepository.fetchUserNotifications(event.user.user.id, accessToken!);

    final List<String> userIdsFromNotificationSources = _getRelevantUserIdsFromNotifications(notifications);
    final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(NotificationsLoaded(notifications: notifications, user: event.user, userProfileMap: userIdProfileMap));
  }

  List<String> _getRelevantUserIdsFromNotifications(List<AppNotification> notifications) {
    final userFollowRequestNotificationUsers = notifications
        .where((element) => element.notificationType == "UserFollowRequest")
        .map((e) => e.data['requestingUser'] as String)
        .toSet()
        .toList();
    final userCommentedOnPostNotificationUsers = notifications
        .where((element) => element.notificationType == "UserCommentedOnPost")
        .map((e) {
          final List<dynamic> data = e.data['commentingUsers'];
          return data.map((e) => e as String);
        })
        .expand((element) => element)
        .toSet()
        .toList();
    final postCreatorUsers = notifications
        .where((element) => element.notificationType == "UserCommentedOnPost")
        .map((e) {
          try {
            final v = e.data['postCreatorId'] as String;
            return v;
          } catch (e) {
            return null;
          }
        })
        .whereType<String>()
        .toSet()
        .toList();
    final userLikedPostNotificationUsers = notifications
        .where((element) => element.notificationType == "UserLikedPost")
        .map((e) {
          final List<dynamic> data = e.data['likingUsers'];
          return data.map((e) => e as String);
        })
        .expand((element) => element)
        .toSet()
        .toList();

    final userIdList = [
      ...userFollowRequestNotificationUsers,
      ...userCommentedOnPostNotificationUsers,
      ...userLikedPostNotificationUsers,
      ...postCreatorUsers
    ];
    return userIdList.toSet().toList();
  }

}
