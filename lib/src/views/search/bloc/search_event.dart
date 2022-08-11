import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

class SearchQuerySubmitted extends SearchEvent {
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

class SearchQueryReset extends SearchEvent {

  const SearchQueryReset();

  @override
  List<Object?> get props => [];
}