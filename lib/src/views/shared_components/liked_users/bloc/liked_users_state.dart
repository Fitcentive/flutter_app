import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class LikedUsersState extends Equatable {

  const LikedUsersState();

  @override
  List<Object> get props => [];

}

class LikedUsersStateInitial extends LikedUsersState {
  const LikedUsersStateInitial();

  @override
  List<Object> get props => [];
}

class LikedUsersProfilesLoading extends LikedUsersState {
  const LikedUsersProfilesLoading();

  @override
  List<Object> get props => [];
}

class LikedUsersProfilesLoaded extends LikedUsersState {
  final List<PublicUserProfile> userProfiles;

  const LikedUsersProfilesLoaded({required this.userProfiles});

  @override
  List<Object> get props => [userProfiles];
}


