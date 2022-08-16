import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';

abstract class NotificationsEvent extends Equatable {

  const NotificationsEvent();

  @override
  List<Object> get props => [];

}

class FetchNotifications extends NotificationsEvent {
  final AuthenticatedUser user;

  const FetchNotifications({required this.user});

  @override
  List<Object> get props => [];
}

class ReFetchNotifications extends NotificationsEvent {
  final AuthenticatedUser user;

  const ReFetchNotifications({required this.user});

  @override
  List<Object> get props => [];
}


class NotificationInteractedWith extends NotificationsEvent {
  final AuthenticatedUser targetUser;
  final String requestingUserId;
  final AppNotification notification;
  final bool isApproved;


  const NotificationInteractedWith({
    required this.requestingUserId,
    required this.targetUser,
    required this.notification,
    required this.isApproved
  });

  @override
  List<Object> get props => [targetUser, notification, isApproved];
}

class MarkNotificationsAsRead extends NotificationsEvent {
  final String currentUserId;
  final List<String> notificationIds;

  const MarkNotificationsAsRead({
    required this.currentUserId,
    required this.notificationIds,
  });

  @override
  List<Object> get props => [currentUserId, notificationIds];
}