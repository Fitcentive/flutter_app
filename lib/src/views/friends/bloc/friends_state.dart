
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class FollowersState extends Equatable {
  const FollowersState();
}

class FriendsStateInitial extends FollowersState {
  const FriendsStateInitial();

  @override
  List<Object> get props => [];
}

class FriendsDataLoading extends FollowersState {

  final String userId;

  const FriendsDataLoading({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FriendsDataLoaded extends FollowersState {
  final String userId;
  final List<PublicUserProfile> userProfiles;
  final bool doesNextPageExist;

  const FriendsDataLoaded({
    required this.userId,
    required this.userProfiles,
    required this.doesNextPageExist
  });

  @override
  List<Object> get props => [userId, userProfiles, doesNextPageExist];
}