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

class PullToRefreshEvent extends NotificationsEvent {
  final AuthenticatedUser user;

  const PullToRefreshEvent({required this.user});

  @override
  List<Object> get props => [user];
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