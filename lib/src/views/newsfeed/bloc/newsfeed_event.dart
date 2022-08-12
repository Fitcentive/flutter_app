import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class NewsFeedEvent extends Equatable {
  const NewsFeedEvent();
}

class NewsFeedFetchRequested extends NewsFeedEvent {
  final AuthenticatedUser user;
  final int createdBefore;
  final int limit;

  const NewsFeedFetchRequested({
    required this.user,
    required this.createdBefore,
    required this.limit
  });

  @override
  List<Object> get props => [user, createdBefore, limit];
}

class NewsFeedReFetchRequested extends NewsFeedEvent {
  final AuthenticatedUser user;
  final int createdBefore;
  final int limit;

  const NewsFeedReFetchRequested({
    required this.user,
    required this.createdBefore,
    required this.limit
  });

  @override
  List<Object> get props => [user, createdBefore, limit];
}

class LikePostForUser extends NewsFeedEvent {
  final String userId;
  final String postId;

  const LikePostForUser({required this.userId, required this.postId});

  @override
  List<Object> get props => [userId, postId];
}

class UnlikePostForUser extends NewsFeedEvent {
  final String userId;
  final String postId;

  const UnlikePostForUser({required this.userId, required this.postId});

  @override
  List<Object> get props => [userId, postId];
}