import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';

abstract class NewsFeedState extends Equatable {
  const NewsFeedState();
}

class NewsFeedStateInitial extends NewsFeedState {
  const NewsFeedStateInitial();

  @override
  List<Object?> get props => [];
}

class NewsFeedDataLoading extends NewsFeedState {

  const NewsFeedDataLoading();

  @override
  List<Object?> get props => [];
}

class NewsFeedDataReady extends NewsFeedState {
  final AuthenticatedUser user;
  final List<SocialPost> posts;
  final List<PostsWithLikedUserIds> postsWithLikedUserIds;
  final Map<String, PublicUserProfile> userIdProfileMap;
  final Map<String, List<SocialPostComment>> postIdCommentsMap;
  final bool doesNextPageExist;

  const NewsFeedDataReady({
    required this.user,
    required this.posts,
    required this.postsWithLikedUserIds,
    required this.userIdProfileMap,
    required this.doesNextPageExist,
    required this.postIdCommentsMap,
  });


  @override
  List<Object?> get props => [
    user,
    posts,
    postsWithLikedUserIds,
    userIdProfileMap,
    doesNextPageExist,
    postIdCommentsMap
  ];
}