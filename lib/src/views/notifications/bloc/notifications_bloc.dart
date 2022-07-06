import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/notification_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_event.dart';
import 'package:flutter_app/src/views/notifications/bloc/notifications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository notificationsRepository;
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  NotificationsBloc({
    required this.notificationsRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const NotificationsInitial()) {
    on<FetchNotifications>(_fetchNotifications);
    on<PullToRefreshEvent>(_pullToRefresh);
    on<NotificationInteractedWith>(_notificationInteractedWith);
  }

  void _notificationInteractedWith(NotificationInteractedWith event, Emitter<NotificationsState> emit) async {
    if (event.notification.isInteractive && event.notification.notificationType == "UserFollowRequest") {
      final accessToken = await secureStorage.read(key: event.targetUser.authTokens.accessTokenSecureStorageKey);
      await userRepository.applyUserDecisionToFollowRequest(
          event.requestingUserId,
          event.targetUser.user.id,
          event.isApproved,
          accessToken!
      );
      await notificationsRepository
          .updateUserNotification(event.targetUser.user.id, event.notification, event.isApproved, accessToken);
      add(FetchNotifications(user: event.targetUser));
    }
  }

  void _fetchNotifications(FetchNotifications event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading());
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final List<AppNotification> notifications =
        await notificationsRepository.fetchUserNotifications(event.user.user.id, accessToken!);

    final List<String> userIdsFromNotificationSources = _getRelevantUserIdsFromNotifications(notifications);
    final List<UserProfile> userProfileDetails =
        await userRepository.getUserProfiles(userIdsFromNotificationSources, accessToken);
    final Map<String, UserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(NotificationsLoaded(notifications: notifications, user: event.user, userProfileMap: userIdProfileMap));
  }

  List<String> _getRelevantUserIdsFromNotifications(List<AppNotification> notifications) {
    return notifications
        .where((element) => element.notificationType == "UserFollowRequest")
        .map((e) => e.data['requestingUser'] as String)
        .toSet()
        .toList();
  }

  void _pullToRefresh(PullToRefreshEvent event, Emitter<NotificationsState> emit) async {
    // todo - yet to implement
  }
}
