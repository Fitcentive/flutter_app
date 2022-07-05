import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

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
  List<Object> get props => [];
}