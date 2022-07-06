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

class UsernameResolved extends UserProfileState {
  final String? username;

  const UsernameResolved({this.username});

  @override
  List<Object?> get props => [username];
}