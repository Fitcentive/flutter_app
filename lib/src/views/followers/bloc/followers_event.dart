import 'package:equatable/equatable.dart';

abstract class FollowersEvent extends Equatable {
  const FollowersEvent();
}

class FetchFollowersRequested extends FollowersEvent {
  final String userId;
  final int limit;
  final int offset;

  const FetchFollowersRequested({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, limit, offset];
}

class ReFetchFollowersRequested extends FollowersEvent {
  final String userId;
  final int limit;
  final int offset;

  const ReFetchFollowersRequested({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, limit, offset];
}