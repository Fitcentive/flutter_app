import 'package:equatable/equatable.dart';

abstract class UserProfileEvent extends Equatable {

  const UserProfileEvent();

  @override
  List<Object> get props => [];

}

class FetchUserUsername extends UserProfileEvent {

  final String userId;

  const FetchUserUsername({required this.userId});

  @override
  List<Object> get props => [userId];

}
