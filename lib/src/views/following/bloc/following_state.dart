
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class FollowingState extends Equatable {
  const FollowingState();
}

class FollowingStateInitial extends FollowingState {
  const FollowingStateInitial();

  @override
  List<Object> get props => [];
}

class FollowingUsersDataLoading extends FollowingState {

  final String userId;

  const FollowingUsersDataLoading({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FollowingUsersDataLoaded extends FollowingState {

  final String userId;
  final List<PublicUserProfile> userProfiles;

  const FollowingUsersDataLoaded({required this.userId, required this.userProfiles});

  @override
  List<Object> get props => [userId, userProfiles];
}