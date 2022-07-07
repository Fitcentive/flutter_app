import 'package:equatable/equatable.dart';

abstract class FollowingEvent extends Equatable {
  const FollowingEvent();
}

class FetchFollowingUsersRequested extends FollowingEvent {

  final String userId;

  const FetchFollowingUsersRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}