import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/discover_recommendation.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoverRecommendationsState extends Equatable {
  const DiscoverRecommendationsState();

  @override
  List<Object?> get props => [];
}

class DiscoverRecommendationsStateInitial extends DiscoverRecommendationsState {

  const DiscoverRecommendationsStateInitial();
}

class DiscoverRecommendationsLoading extends DiscoverRecommendationsState {

  const DiscoverRecommendationsLoading();
}

class DiscoverRecommendationsReady extends DiscoverRecommendationsState {
  final PublicUserProfile currentUserProfile;
  final List<DiscoverRecommendation> recommendations;
  final int discoveredUsersViewedForMonthCount;

  const DiscoverRecommendationsReady({
    required this.currentUserProfile,
    required this.recommendations,
    required this.discoveredUsersViewedForMonthCount,
  });

  @override
  List<Object?> get props => [currentUserProfile, recommendations, discoveredUsersViewedForMonthCount];
}
