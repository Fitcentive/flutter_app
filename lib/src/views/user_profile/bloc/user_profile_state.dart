import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
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

class UsernameLoading extends UserProfileState {

  const UsernameLoading();

  @override
  List<Object?> get props => [];
}

class RequiredDataResolved extends UserProfileState {
  final AuthenticatedUser currentUser;
  final UserFollowStatus userFollowStatus;

  const RequiredDataResolved({
    required this.userFollowStatus,
    required this.currentUser
  });

  @override
  List<Object?> get props => [userFollowStatus, currentUser];
}