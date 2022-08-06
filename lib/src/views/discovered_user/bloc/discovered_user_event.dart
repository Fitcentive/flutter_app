import 'package:equatable/equatable.dart';

abstract class DiscoveredUserEvent extends Equatable {
  const DiscoveredUserEvent();

  @override
  List<Object?> get props => [];
}

// Fetches user discover preferences
class FetchDiscoveredUserPreferences extends DiscoveredUserEvent {
  final String userId;

  const FetchDiscoveredUserPreferences(this.userId);

  @override
  List<Object?> get props => [userId];
}
