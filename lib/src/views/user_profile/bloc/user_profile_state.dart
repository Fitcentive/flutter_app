import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/models/user_friend_status.dart';

abstract class UserProfileState extends Equatable {

  const UserProfileState();

  @override
  List<Object?> get props => [];

}

class UserProfileInitial extends UserProfileState {

  const UserProfileInitial();

  @override
  List<Object?> get props => [];
}

class DataLoading extends UserProfileState {

  const DataLoading();

  @override
  List<Object?> get props => [];
}

class RequiredDataResolved extends UserProfileState {
  final AuthenticatedUser currentUser;
  final UserFriendStatus userFollowStatus;
  final List<SocialPost>? userPosts;
  final List<PostsWithLikedUserIds>? usersWhoLikedPosts;
  final Map<String, List<SocialPostComment>>? postIdCommentsMap;
  final Map<String, PublicUserProfile>? userIdProfileMap;

  final String? selectedPostId;
  final String? chatRoomId;

  final bool doesNextPageExist;

  const RequiredDataResolved({
    required this.userFollowStatus,
    required this.currentUser,
    required this.userPosts,
    required this.usersWhoLikedPosts,
    required this.postIdCommentsMap,
    required this.userIdProfileMap,
    required this.selectedPostId,
    required this.chatRoomId,
    required this.doesNextPageExist,
  });

  RequiredDataResolved copyWith({
    required String? newPostId,
    required String? chatRoomId,
    required bool doesNextPageExist,
  }) {
    return RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        userIdProfileMap: userIdProfileMap,
        currentUser: currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: usersWhoLikedPosts,
        postIdCommentsMap: postIdCommentsMap,
        selectedPostId: newPostId,
        chatRoomId: chatRoomId,
        doesNextPageExist: doesNextPageExist,
    );
  }

  @override
  List<Object?> get props => [
    userFollowStatus,
    currentUser,
    userPosts,
    usersWhoLikedPosts,
    selectedPostId,
    chatRoomId,
    postIdCommentsMap,
    userIdProfileMap,
    doesNextPageExist,
  ];
}

class GoToUserChatView extends UserProfileState {
  final String roomId;

  const GoToUserChatView({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class TargetUserChatNotEnabled extends UserProfileState {

  const TargetUserChatNotEnabled();

  @override
  List<Object?> get props => [];
}