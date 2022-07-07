import 'package:equatable/equatable.dart';

abstract class FollowersEvent extends Equatable {
  const FollowersEvent();
}

class FetchFollowersRequested extends FollowersEvent {

  final String userId;

  const FetchFollowersRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}