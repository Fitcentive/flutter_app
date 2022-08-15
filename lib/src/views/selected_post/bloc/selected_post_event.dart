import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';

abstract class SelectedPostEvent extends Equatable {

  const SelectedPostEvent();

  @override
  List<Object> get props => [];

}

class FetchSelectedPost extends SelectedPostEvent {
  final String currentUserId;
  final String postId;

  const FetchSelectedPost({
    required this.currentUserId,
    required this.postId,
  });

  @override
  List<Object> get props => [currentUserId, postId];
}

class PostAlreadyProvidedByParent extends SelectedPostEvent {
  final String currentUserId;
  final SocialPost currentPost;
  final List<SocialPostComment> currentPostComments;
  final PostsWithLikedUserIds likedUsersForCurrentPost;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const PostAlreadyProvidedByParent({
    required this.currentUserId,
    required this.currentPost,
    required this.currentPostComments,
    required this.likedUsersForCurrentPost,
    required this.userIdProfileMap
  });

  @override
  List<Object> get props => [
    currentPost,
    currentPostComments,
    likedUsersForCurrentPost,
    userIdProfileMap,
    currentUserId
  ];
}

class LikePostForUser extends SelectedPostEvent {
  final String currentUserId;
  final String postId;

  const LikePostForUser({
    required this.currentUserId,
    required this.postId,
  });

  @override
  List<Object> get props => [postId, currentUserId];
}

class UnlikePostForUser extends SelectedPostEvent {
  final String currentUserId;
  final String postId;

  const UnlikePostForUser({
    required this.currentUserId,
    required this.postId,
  });

  @override
  List<Object> get props => [postId, currentUserId];
}

class AddNewComment extends SelectedPostEvent {
  final String postId;
  final String userId;
  final String comment;

  const AddNewComment({
    required this.postId,
    required this.userId,
    required this.comment,
  });

  @override
  List<Object> get props => [comment, postId, comment];
}