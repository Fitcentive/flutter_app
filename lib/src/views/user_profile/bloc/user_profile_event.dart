import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/user_follow_status.dart';

abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchRequiredData extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String userId;

  const FetchRequiredData({required this.userId, required this.currentUser});

  @override
  List<Object?> get props => [userId, currentUser];
}

class FetchUserPostsData extends UserProfileEvent {
  final UserFollowStatus userFollowStatus;
  final AuthenticatedUser currentUser;
  final String userId;

  const FetchUserPostsData({required this.userFollowStatus, required this.userId, required this.currentUser});

  @override
  List<Object?> get props => [userFollowStatus, userId, currentUser];
}

class RequestToFollowUser extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;
  final List<SocialPost>? userPosts;
  final List<PostsWithLikedUserIds>? usersWhoLikedPosts;

  const RequestToFollowUser({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
    required this.userPosts,
    required this.usersWhoLikedPosts,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus, userPosts, usersWhoLikedPosts];
}

class UnfollowUser extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;
  final List<SocialPost>? userPosts;
  final List<PostsWithLikedUserIds>? usersWhoLikedPosts;

  const UnfollowUser({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
    required this.userPosts,
    required this.usersWhoLikedPosts,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus, userPosts, usersWhoLikedPosts];
}

class LikePostForUser extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String postId;

  const LikePostForUser({
    required this.currentUser,
    required this.postId,
  });

  @override
  List<Object?> get props => [postId, currentUser];
}

class UnlikePostForUser extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String postId;

  const UnlikePostForUser({
    required this.currentUser,
    required this.postId,
  });

  @override
  List<Object?> get props => [postId, currentUser];
}

class RemoveUserFromCurrentUserFollowers extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;
  final List<SocialPost>? userPosts;
  final List<PostsWithLikedUserIds>? usersWhoLikedPosts;

  const RemoveUserFromCurrentUserFollowers({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
    required this.userPosts,
    required this.usersWhoLikedPosts,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus, userPosts, usersWhoLikedPosts];
}

class ApplyUserDecisionToFollowRequest extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;
  final bool isFollowRequestApproved;
  final List<SocialPost>? userPosts;
  final List<PostsWithLikedUserIds>? usersWhoLikedPosts;

  const ApplyUserDecisionToFollowRequest({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
    required this.isFollowRequestApproved,
    required this.userPosts,
    required this.usersWhoLikedPosts
  });

  @override
  List<Object?> get props => [
    targetUserId,
    currentUser,
    userFollowStatus,
    isFollowRequestApproved,
    userPosts,
    usersWhoLikedPosts
  ];
}

class ViewCommentsForSelectedPost extends UserProfileEvent {
  final String postId;

  const ViewCommentsForSelectedPost({required this.postId});

  @override
  List<Object> get props => [postId];
}
