import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoverRecommendationsEvent extends Equatable {
  const DiscoverRecommendationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserDiscoverRecommendations extends DiscoverRecommendationsEvent {
  final PublicUserProfile currentUserProfile;
  final bool isPremiumEnabled;

  const FetchUserDiscoverRecommendations(this.currentUserProfile, this.isPremiumEnabled);

  @override
  List<Object?> get props => [currentUserProfile, isPremiumEnabled];
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