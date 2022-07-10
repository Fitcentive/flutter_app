import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
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

  const RequiredDataResolved({
    required this.userFollowStatus,
    required this.currentUser,
    required this.userPosts,
  });

  @override
  List<Object?> get props => [userFollowStatus, currentUser, userPosts];
}