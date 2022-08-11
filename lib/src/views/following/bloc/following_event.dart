import 'package:equatable/equatable.dart';

abstract class FollowingEvent extends Equatable {
  const FollowingEvent();
}

class ReFetchFollowingUsersRequested extends FollowingEvent {
  final String userId;
  final int limit;
  final int offset;

  const ReFetchFollowingUsersRequested({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, limit, offset];
}

class FetchFollowingUsersRequested extends FollowingEvent {
  final String userId;
  final int limit;
  final int offset;

  const FetchFollowingUsersRequested({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, limit, offset];
}