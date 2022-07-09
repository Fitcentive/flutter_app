import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/social/social_post.dart';

abstract class NewsFeedState extends Equatable {
  const NewsFeedState();
}

class NewsFeedStateInitial extends NewsFeedState {
  const NewsFeedStateInitial();

  @override
  List<Object> get props => [];
}

class NewsFeedDataLoading extends NewsFeedState {

  const NewsFeedDataLoading();

  @override
  List<Object> get props => [];
}

class NewsFeedDataReady extends NewsFeedState {
  final AuthenticatedUser user;
  final List<SocialPost> posts;

  const NewsFeedDataReady({
    required this.user,
    required this.posts
  });

  @override
  List<Object> get props => [user, posts];
}