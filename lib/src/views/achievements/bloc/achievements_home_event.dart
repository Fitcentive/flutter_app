import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';

abstract class AchievementsHomeEvent extends Equatable {
  const AchievementsHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllUserAchievements extends AchievementsHomeEvent {
  final String userId;

  const FetchAllUserAchievements({
    required this.userId
  });

  @override
  List<Object> get props => [
    userId
  ];
}

class TrackViewDetailedAchievement extends AchievementsHomeEvent {
  final UserTrackingEvent event;


  const TrackViewDetailedAchievement(this.event);

  @override
  List<Object> get props => [event];

}
