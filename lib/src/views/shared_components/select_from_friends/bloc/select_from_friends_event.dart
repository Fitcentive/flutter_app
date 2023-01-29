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

class FetchFriendsByQueryRequested extends SelectFromFriendsEvent {
  final String userId;
  final String query;
  final int limit;
  final int offset;

  const FetchFriendsByQueryRequested({
    required this.userId,
    required this.query,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object> get props => [userId, query, limit, offset];
}

// class ResetBackToAllUserFriends extends SelectFromFriendsEvent {
//   final String userId;
//   final List<PublicUserProfile> previouslyFetchedFriends;
//   final bool doesPreviouslyFetchedNextPageExist;
//
//   const ResetBackToAllUserFriends({
//     required this.userId,
//     required this.previouslyFetchedFriends,
//     required this.doesPreviouslyFetchedNextPageExist
//   });
//
//   @override
//   List<Object> get props => [userId, previouslyFetchedFriends, doesPreviouslyFetchedNextPageExist];
// }