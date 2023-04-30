import 'package:equatable/equatable.dart';

abstract class UserSearchEvent extends Equatable {
  const UserSearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserFriends extends UserSearchEvent {
  final String currentUserId;
  final int limit;
  final int offset;

  const FetchUserFriends({
    required this.currentUserId,
    required this.limit,
    required this.offset
  });

  @override
  List<Object?> get props => [currentUserId, limit, offset];
}


class SearchQueryChanged extends UserSearchEvent {
  final String query;

  const SearchQueryChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

class SearchQuerySubmitted extends UserSearchEvent {
  final String query;
  final int limit;
  final int offset;

  const SearchQuerySubmitted({
    required this.query,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object?> get props => [query, limit, offset];
}

class SearchQueryReset extends UserSearchEvent {
  final String currentUserId;

  const SearchQueryReset({
    required this.currentUserId
  });

  @override
  List<Object?> get props => [currentUserId];
}