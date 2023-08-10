import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoverRecommendationsEvent extends Equatable {
  const DiscoverRecommendationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserDiscoverRecommendations extends DiscoverRecommendationsEvent {
  final PublicUserProfile currentUserProfile;
  final bool shouldIncreaseRadius;
  final int limit;
  final int skip;

  const FetchUserDiscoverRecommendations({
    required this.currentUserProfile,
    required this.shouldIncreaseRadius,
    required this.limit,
    required this.skip
  });

  @override
  List<Object?> get props => [currentUserProfile, shouldIncreaseRadius, limit, skip];
}


class FetchAdditionalUserDiscoverRecommendations extends DiscoverRecommendationsEvent {
  final PublicUserProfile currentUserProfile;
  final bool shouldIncreaseRadius;
  final int limit;
  final int skip;

  const FetchAdditionalUserDiscoverRecommendations({
    required this.currentUserProfile,
    required this.shouldIncreaseRadius,
    required this.limit,
    required this.skip,
  });

  @override
  List<Object?> get props => [currentUserProfile, limit, skip, shouldIncreaseRadius];
}

class UpsertNewlyDiscoveredUser extends DiscoverRecommendationsEvent {
  final String currentUserId;
  final String newUserId;

  const UpsertNewlyDiscoveredUser({required this.currentUserId, required this.newUserId});

  @override
  List<Object?> get props => [currentUserId, newUserId];
}

class TrackRejectNewDiscoveredUserEvent extends DiscoverRecommendationsEvent {

  const TrackRejectNewDiscoveredUserEvent();

  @override
  List<Object?> get props => [];
}

class TrackViewNewDiscoveredUserEvent extends DiscoverRecommendationsEvent {

  const TrackViewNewDiscoveredUserEvent();

  @override
  List<Object?> get props => [];
}