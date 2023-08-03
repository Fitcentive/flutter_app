import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoveredUserEvent extends Equatable {
  const DiscoveredUserEvent();

  @override
  List<Object?> get props => [];
}

// Fetches user discover preferences
class FetchDiscoveredUserPreferences extends DiscoveredUserEvent {
  final String currentUserId;
  final String otherUserId;

  const FetchDiscoveredUserPreferences(this.currentUserId, this.otherUserId);

  @override
  List<Object?> get props => [otherUserId, currentUserId];
}

class GetChatRoom extends DiscoveredUserEvent {
  final PublicUserProfile otherUserProfile;

  const GetChatRoom({required this.otherUserProfile});

  @override
  List<Object> get props => [otherUserProfile];
}