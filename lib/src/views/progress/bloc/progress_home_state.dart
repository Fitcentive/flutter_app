import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/progress/progress_insights.dart';

abstract class ProgressHomeState extends Equatable {
  const ProgressHomeState();

  @override
  List<Object?> get props => [];
}

class ProgressStateInitial extends ProgressHomeState {

  const ProgressStateInitial();

  @override
  List<Object?> get props => [];
}

class ProgressLoading extends ProgressHomeState {

  const ProgressLoading();

  @override
  List<Object?> get props => [];
}

class ProgressLoaded extends ProgressHomeState {
  final ProgressInsights insights;
  final FitnessUserProfile? fitnessUserProfile;

  const ProgressLoaded({
    required this.insights,
    required this.fitnessUserProfile,
  });

  @override
  List<Object?> get props => [
    insights,
    fitnessUserProfile
  ];

}