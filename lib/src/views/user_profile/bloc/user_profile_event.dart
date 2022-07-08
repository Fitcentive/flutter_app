import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
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

class RequestToFollowUser extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;

  const RequestToFollowUser({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus];
}

class UnfollowUser extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;

  const UnfollowUser({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus];
}

class RemoveUserFromCurrentUserFollowers extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;

  const RemoveUserFromCurrentUserFollowers({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus];
}

class ApplyUserDecisionToFollowRequest extends UserProfileEvent {
  final AuthenticatedUser currentUser;
  final String targetUserId;
  final UserFollowStatus userFollowStatus;
  final bool isFollowRequestApproved;

  const ApplyUserDecisionToFollowRequest({
    required this.targetUserId,
    required this.currentUser,
    required this.userFollowStatus,
    required this.isFollowRequestApproved,
  });

  @override
  List<Object?> get props => [targetUserId, currentUser, userFollowStatus, isFollowRequestApproved];
}
