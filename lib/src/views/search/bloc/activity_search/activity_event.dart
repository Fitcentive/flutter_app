import 'package:equatable/equatable.dart';

abstract class ActivitySearchEvent extends Equatable {
  const ActivitySearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllActivityInfo extends ActivitySearchEvent {

  const FetchAllActivityInfo();

  @override
  List<Object?> get props => [];
}

class ActivityFilterSearchQueryChanged extends ActivitySearchEvent {
  final String searchQuery;

  const ActivityFilterSearchQueryChanged({ required this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}
