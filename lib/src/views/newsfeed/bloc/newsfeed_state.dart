import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';

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
  final String? selectedPostId;
  final bool doesNextPageExist;

  const NewsFeedDataReady({
    required this.user,
    required this.posts,
    required this.postsWithLikedUserIds,
    required this.userIdProfileMap,
    required this.selectedPostId,
    required this.doesNextPageExist,
  });

  NewsFeedDataReady copyWith({
    required String newPostId,
    required bool doesNextPageExist,
  }) {
    return NewsFeedDataReady(
        user: user,
        posts: posts,
        postsWithLikedUserIds: postsWithLikedUserIds,
        userIdProfileMap: userIdProfileMap,
        selectedPostId: newPostId,
        doesNextPageExist: doesNextPageExist,
    );
  }

  @override
  List<Object?> get props => [user, posts, postsWithLikedUserIds, userIdProfileMap, selectedPostId, doesNextPageExist];
}