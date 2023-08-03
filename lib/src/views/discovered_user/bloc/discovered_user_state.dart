import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_gym_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_friend_status.dart';

abstract class DiscoveredUserState extends Equatable {
  const DiscoveredUserState();

  @override
  List<Object?> get props => [];
}

class DiscoveredUserStateInitial extends DiscoveredUserState {
  const DiscoveredUserStateInitial();
}

class DiscoveredUserDataLoading extends DiscoveredUserState {
  const DiscoveredUserDataLoading();
}

class DiscoveredUserPreferencesFetched extends DiscoveredUserState {
  final UserDiscoveryPreferences? discoveryPreferences;
  final UserFitnessPreferences? fitnessPreferences;
  final UserPersonalPreferences? personalPreferences;
  final UserGymPreferences? gymPreferences;
  final PublicUserProfile otherUserProfile;
  final num discoverScore;
  final UserFriendStatus userFriendStatus;

  const DiscoveredUserPreferencesFetched({
    this.discoveryPreferences,
    this.fitnessPreferences,
    this.personalPreferences,
    this.gymPreferences,
    required this.otherUserProfile,
    required this.discoverScore,
    required this.userFriendStatus,
  });

  @override
  List<Object?> get props => [
    discoveryPreferences,
    fitnessPreferences,
    personalPreferences,
    gymPreferences,
    otherUserProfile,
    discoverScore,
    userFriendStatus,
  ];
}

class GoToUserChatView extends DiscoveredUserState {
  final String roomId;
  final PublicUserProfile otherUserProfile;

  const GoToUserChatView({required this.roomId, required this.otherUserProfile});

  @override
  List<Object?> get props => [roomId, otherUserProfile];
}

class TargetUserChatNotEnabled extends DiscoveredUserState {

  const TargetUserChatNotEnabled();

  @override
  List<Object?> get props => [];
}