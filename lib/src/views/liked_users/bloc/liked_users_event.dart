import 'package:equatable/equatable.dart';

abstract class LikedUsersEvent extends Equatable {

  const LikedUsersEvent();

  @override
  List<Object> get props => [];

}

class FetchedLikedUserProfiles extends LikedUsersEvent {
  final List<String> userIds;

  const FetchedLikedUserProfiles({required this.userIds});

  @override
  List<Object> get props => [userIds];
}