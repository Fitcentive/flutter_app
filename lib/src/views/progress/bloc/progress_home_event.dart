import 'package:equatable/equatable.dart';

abstract class ProgressHomeEvent extends Equatable {
  const ProgressHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchProgressInsights extends ProgressHomeEvent {
  final String userId;

  const FetchProgressInsights({
    required this.userId
  });

  @override
  List<Object> get props => [
    userId
  ];
}
