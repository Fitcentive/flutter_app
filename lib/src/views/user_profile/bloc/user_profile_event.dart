import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

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
  final String? resolvedUsername;
  final bool hasCurrentUserAlreadyRequestedToFollowUser;

  const RequestToFollowUser(
      {required this.targetUserId,
      required this.currentUser,
      required this.resolvedUsername,
      required this.hasCurrentUserAlreadyRequestedToFollowUser});

  @override
  List<Object?> get props => [targetUserId, currentUser, resolvedUsername];
}
