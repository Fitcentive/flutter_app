import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchFitnessUserProfile extends SearchEvent {
  final String currentUserId;

  const FetchFitnessUserProfile({
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [currentUserId];
}