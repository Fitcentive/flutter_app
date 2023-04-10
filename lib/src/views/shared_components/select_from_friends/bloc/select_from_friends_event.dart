import 'package:equatable/equatable.dart';

abstract class SelectFromFriendsEvent extends Equatable {
  const SelectFromFriendsEvent();
}

class FetchFriendsRequested extends SelectFromFriendsEvent {
  final String userId;
  final int limit;
  final int offset;

  const FetchFriendsRequested({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, limit, offset];
}

class ReFetchFriendsRequested extends SelectFromFriendsEvent {
  final String userId;
  final int limit;
  final int offset;

  const ReFetchFriendsRequested({
    required this.userId,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, limit, offset];
}


class FetchFriendsByQueryRequested extends SelectFromFriendsEvent {
  final String userId;
  final String query;
  final int limit;
  final int offset;
  final bool isRestrictedOnlyToFriends;

  const FetchFriendsByQueryRequested({
    required this.userId,
    required this.query,
    required this.limit,
    required this.offset,
    required this.isRestrictedOnlyToFriends,
  });

  @override
  List<Object> get props => [userId, query, limit, offset, isRestrictedOnlyToFriends];
}