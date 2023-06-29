import 'dart:convert';

import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
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
    on<ReFetchNotifications>(_reFetchNotifications);
    on<NotificationInteractedWith>(_notificationInteractedWith);
    on<MarkNotificationsAsRead>(_markNotificationsAsRead);
  }

  void _markNotificationsAsRead(MarkNotificationsAsRead event, Emitter<NotificationsState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await notificationsRepository.markNotificationsAsRead(event.currentUserId, event.notificationIds, accessToken!);
  }

  void _notificationInteractedWith(NotificationInteractedWith event, Emitter<NotificationsState> emit) async {
    if (event.notification.isInteractive && event.notification.notificationType == "UserFriendRequest") {
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
            userProfileMap: currentState.userProfileMap,
            doesNextPageExist: currentState.doesNextPageExist
        ));
      }

      final accessToken = await secureStorage.read(key: event.targetUser.authTokens.accessTokenSecureStorageKey);
      await socialMediaRepository.applyUserDecisionToFriendRequest(
          event.requestingUserId,
          event.targetUser.user.id,
          event.isApproved,
          accessToken!
      );
      await notificationsRepository
          .updateUserNotification(event.targetUser.user.id, event.notification, event.isApproved, accessToken);
    }
  }

  void _reFetchNotifications(ReFetchNotifications event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading());
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final List<AppNotification> notifications =
    await notificationsRepository.fetchUserNotifications(
        event.user.user.id, accessToken!,
        ConstantUtils.DEFAULT_LIMIT,
        ConstantUtils.DEFAULT_OFFSET
    );

    final List<String> userIdsFromNotificationSources = _getRelevantUserIdsFromNotifications(notifications);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
    final doesNextPageExist = notifications.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

    emit(NotificationsLoaded(
        notifications: notifications,
        user: event.user,
        userProfileMap: userIdProfileMap,
        doesNextPageExist: doesNextPageExist
    ));
  }

  void _fetchNotifications(FetchNotifications event, Emitter<NotificationsState> emit) async {
    final currentState = state;
    if (currentState is NotificationsInitial) {
      emit(const NotificationsLoading());
      final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
      final List<AppNotification> notifications =
      await notificationsRepository.fetchUserNotifications(
          event.user.user.id, accessToken!,
          ConstantUtils.DEFAULT_LIMIT,
          ConstantUtils.DEFAULT_OFFSET
      );

      final List<String> userIdsFromNotificationSources = _getRelevantUserIdsFromNotifications(notifications);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
      final doesNextPageExist = notifications.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

      emit(NotificationsLoaded(
              notifications: notifications,
              user: event.user,
              userProfileMap: userIdProfileMap,
              doesNextPageExist: doesNextPageExist
          ));
    }
    else if (currentState is NotificationsLoaded && currentState.doesNextPageExist) {
      final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
      final List<AppNotification> notifications =
      await notificationsRepository.fetchUserNotifications(
          event.user.user.id, accessToken!,
          ConstantUtils.DEFAULT_LIMIT,
          currentState.notifications.length
      );

      final List<String> userIdsFromNotificationSources = _getRelevantUserIdsFromNotifications(notifications);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
      final doesNextPageExist = notifications.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

      final completeNotifications = [...currentState.notifications, ...notifications];
      final completeUserIdProfileMap = {...currentState.userProfileMap, ...userIdProfileMap};

      userRepository.trackUserEvent(ViewNotifications(), accessToken);

      emit(NotificationsLoaded(
          notifications: completeNotifications,
          user: event.user,
          userProfileMap: completeUserIdProfileMap,
          doesNextPageExist: doesNextPageExist
      ));
    }
    
  }

  List<String> _getRelevantUserIdsFromNotifications(List<AppNotification> notifications) {
    final userFriendRequestNotificationUsers = notifications
        .where((element) => element.notificationType == "UserFriendRequest")
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

    final participantAddedToMeetupNotificationUsers = notifications
        .where((element) => element.notificationType == "ParticipantAddedToMeetup")
        .map((e) {
      final participantId = e.data['participantId'] as String;
      final meetupOwnerId = e.data['meetupOwnerId'] as String;
      return [participantId, meetupOwnerId];
    })
        .expand((element) => element)
        .toSet()
        .toList();

    final participantAddedAvailabilityToMeetupNotificationUsers = notifications
        .where((element) => element.notificationType == "ParticipantAddedAvailabilityToMeetup")
        .map((e) {
      final participantId = e.data['participantId'] as String;
      final meetupOwnerId = e.data['meetupOwnerId'] as String;
      return [participantId, meetupOwnerId];
    })
        .expand((element) => element)
        .toSet()
        .toList();

    final meetupDecisionNotificationUsers = notifications
        .where((element) => element.notificationType == "MeetupDecision")
        .map((e) {
      final participantId = e.data['participantId'] as String;
      final meetupOwnerId = e.data['meetupOwnerId'] as String;
      return [participantId, meetupOwnerId];
    })
        .expand((element) => element)
        .toSet()
        .toList();

    final meetupLocationChangedNotificationUsers = notifications
        .where((element) => element.notificationType == "MeetupLocationChanged")
        .map((e) {
      final participantId = e.data['targetUserId'] as String;
      final meetupOwnerId = e.data['meetupOwnerId'] as String;
      return [participantId, meetupOwnerId];
    })
        .expand((element) => element)
        .toSet()
        .toList();

    final userIdList = [
      ...userFriendRequestNotificationUsers,
      ...userCommentedOnPostNotificationUsers,
      ...userLikedPostNotificationUsers,
      ...postCreatorUsers,
      ...meetupDecisionNotificationUsers,
      ...participantAddedToMeetupNotificationUsers,
      ...participantAddedAvailabilityToMeetupNotificationUsers,
      ...meetupLocationChangedNotificationUsers,
      ConstantUtils.staticDeletedUserId,
    ];
    return userIdList.toSet().toList();
  }

}
