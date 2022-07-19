import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/user_follow_status.dart';

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
  final UserFollowStatus userFollowStatus;
  final List<SocialPost>? userPosts;
  final List<PostsWithLikedUserIds>? usersWhoLikedPosts;

  final String? selectedPostId;
  final String? chatRoomId;

  const RequiredDataResolved({
    required this.userFollowStatus,
    required this.currentUser,
    required this.userPosts,
    required this.usersWhoLikedPosts,
    required this.selectedPostId,
    required this.chatRoomId
  });

  RequiredDataResolved copyWith({
    required String? newPostId,
    required String? chatRoomId,
  }) {
    return RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: usersWhoLikedPosts,
        selectedPostId: newPostId,
        chatRoomId: chatRoomId
    );
  }

  @override
  List<Object?> get props => [userFollowStatus, currentUser, userPosts, usersWhoLikedPosts, selectedPostId, chatRoomId];
}

class GoToUserChatView extends UserProfileState {
  final String roomId;

  const GoToUserChatView({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}