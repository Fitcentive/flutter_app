import 'package:equatable/equatable.dart';

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();
}

class FetchFriendsRequested extends FriendsEvent {
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

class ReFetchFriendsRequested extends FriendsEvent {
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

class TrackViewFriendsEvent extends FriendsEvent {

  const TrackViewFriendsEvent();

  @override
  List<Object> get props => [];

}