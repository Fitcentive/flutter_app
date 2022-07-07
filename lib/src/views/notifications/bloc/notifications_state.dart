import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class NotificationsState extends Equatable {

  const NotificationsState();

  @override
  List<Object> get props => [];

}

class NotificationsInitial extends NotificationsState {

  const NotificationsInitial();

  @override
  List<Object> get props => [];
}

class NotificationsLoading extends NotificationsState {

  const NotificationsLoading();

  @override
  List<Object> get props => [];
}

class NotificationsLoaded extends NotificationsState {
  final AuthenticatedUser user;
  final List<AppNotification> notifications;
  final Map<String, PublicUserProfile> userProfileMap;

  const NotificationsLoaded({
    required this.notifications,
    required this.user,
    required this.userProfileMap,
  });

  @override
  List<Object> get props => [notifications, userProfileMap, user];
}