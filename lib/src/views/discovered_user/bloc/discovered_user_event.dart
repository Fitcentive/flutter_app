import 'package:equatable/equatable.dart';

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
