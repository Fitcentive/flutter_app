import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/progress/activity_minutes_per_day.dart';
import 'package:flutter_app/src/models/progress/diary_entries_per_day.dart';
import 'package:flutter_app/src/models/progress/user_step_metrics.dart';
import 'package:flutter_app/src/models/progress/user_weight_metrics.dart';

abstract class DetailedProgressState extends Equatable {
  const DetailedProgressState();

  @override
  List<Object?> get props => [];
}

class DetailedProgressStateInitial extends DetailedProgressState {

  const DetailedProgressStateInitial();

  @override
  List<Object?> get props => [];
}

class DetailedProgressLoading extends DetailedProgressState {

  const DetailedProgressLoading();

  @override
  List<Object?> get props => [];
}

class StepProgressMetricsLoaded extends DetailedProgressState {
  final List<UserStepMetrics> userStepMetrics;

  const StepProgressMetricsLoaded({
    required this.userStepMetrics,
  });

  @override
  List<Object?> get props => [
    userStepMetrics,
  ];
}

class DiaryEntriesProgressMetricsLoaded extends DetailedProgressState {
  final List<DiaryEntriesPerDay> userDiaryEntryMetrics;

  const DiaryEntriesProgressMetricsLoaded({
    required this.userDiaryEntryMetrics,
  });

  @override
  List<Object?> get props => [
    userDiaryEntryMetrics,
  ];
}

class ActivityProgressMetricsLoaded extends DetailedProgressState {
  final List<ActivityMinutesPerDay> userActivityMetrics;

  const ActivityProgressMetricsLoaded({
    required this.userActivityMetrics,
  });

  @override
  List<Object?> get props => [
    userActivityMetrics,
  ];
}

class WeightProgressMetricsLoaded extends DetailedProgressState {
  final List<UserWeightMetrics> userWeightMetrics;

  const WeightProgressMetricsLoaded({
    required this.userWeightMetrics,
  });

  @override
  List<Object?> get props => [
    userWeightMetrics,
  ];
}