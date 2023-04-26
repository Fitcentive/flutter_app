import 'package:equatable/equatable.dart';

abstract class DiscoverHomeEvent extends Equatable {
  const DiscoverHomeEvent();

  @override
  List<Object?> get props => [];
}

// Fetches user discover preferences and previously discovered users
class FetchUserDiscoverData extends DiscoverHomeEvent {
  final String userId;

  const FetchUserDiscoverData(this.userId);

  @override
  List<Object?> get props => [userId];
}


class FetchMoreDiscoveredUsers extends DiscoverHomeEvent {
  final String userId;

  const FetchMoreDiscoveredUsers(this.userId);

  @override
  List<Object?> get props => [userId];
}


class RemoveUserFromListOfDiscoveredUsers extends DiscoverHomeEvent {
  final String currentUserId;
  final String discoveredUserId;

  const RemoveUserFromListOfDiscoveredUsers({
    required this.currentUserId,
    required this.discoveredUserId
  });

  @override
  List<Object?> get props => [currentUserId, discoveredUserId];
}

class AddUserToListOfDiscoveredUsers extends DiscoverHomeEvent {
  final String currentUserId;
  final String discoveredUserId;

  const AddUserToListOfDiscoveredUsers({
    required this.currentUserId,
    required this.discoveredUserId
  });

  @override
  List<Object?> get props => [currentUserId, discoveredUserId];
}