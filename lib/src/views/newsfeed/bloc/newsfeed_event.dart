import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class NewsFeedEvent extends Equatable {
  const NewsFeedEvent();
}

class NewsFeedFetchRequested extends NewsFeedEvent {
  final AuthenticatedUser user;

  const NewsFeedFetchRequested({required this.user});

  @override
  List<Object> get props => [user];
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

class ViewCommentsForSelectedPost extends NewsFeedEvent {
  final String postId;

  const ViewCommentsForSelectedPost({required this.postId});

  @override
  List<Object> get props => [postId];
}