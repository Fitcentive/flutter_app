import 'package:equatable/equatable.dart';

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
  final bool hasCurrentUserAlreadyRequestedToFollowUser;
  final String? username;

  const RequiredDataResolved({this.username, required this.hasCurrentUserAlreadyRequestedToFollowUser});

  @override
  List<Object?> get props => [username, hasCurrentUserAlreadyRequestedToFollowUser];
}