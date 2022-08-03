import 'package:equatable/equatable.dart';

abstract class DiscoverHomeEvent extends Equatable {
  const DiscoverHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserDiscoverPreferences extends DiscoverHomeEvent {
  final String userId;

  const FetchUserDiscoverPreferences(this.userId);

  @override
  List<Object?> get props => [userId];
}