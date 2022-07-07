
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class FollowersState extends Equatable {
  const FollowersState();
}

class FollowersStateInitial extends FollowersState {
  const FollowersStateInitial();

  @override
  List<Object> get props => [];
}

class FollowersDataLoading extends FollowersState {

  final String userId;

  const FollowersDataLoading({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FollowersDataLoaded extends FollowersState {

  final String userId;
  final List<PublicUserProfile> userProfiles;

  const FollowersDataLoaded({required this.userId, required this.userProfiles});

  @override
  List<Object> get props => [userId, userProfiles];
}