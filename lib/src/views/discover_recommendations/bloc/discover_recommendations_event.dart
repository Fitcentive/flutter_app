import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class DiscoverRecommendationsEvent extends Equatable {
  const DiscoverRecommendationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserDiscoverRecommendations extends DiscoverRecommendationsEvent {
  final PublicUserProfile currentUserProfile;

  const FetchUserDiscoverRecommendations(this.currentUserProfile);

  @override
  List<Object?> get props => [currentUserProfile];
}