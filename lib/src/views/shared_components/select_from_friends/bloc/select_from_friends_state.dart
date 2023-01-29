
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class SelectFromFriendsState extends Equatable {
  const SelectFromFriendsState();
}

class SelectFromFriendsStateInitial extends SelectFromFriendsState {
  const SelectFromFriendsStateInitial();

  @override
  List<Object> get props => [];
}

class FriendsDataLoading extends SelectFromFriendsState {

  final String userId;

  const FriendsDataLoading({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FriendsDataLoaded extends SelectFromFriendsState {
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