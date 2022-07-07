import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchStateInitial extends SearchState {

  const SearchStateInitial();

  @override
  List<Object> get props => [];
}

class SearchQueryModified extends SearchState {
  final String query;

  const SearchQueryModified({required this.query});

  @override
  List<Object> get props => [query];
}

class SearchResultsLoading extends SearchState {
  final String query;

  const SearchResultsLoading({required this.query});

  @override
  List<Object> get props => [query];
}

class SearchResultsLoaded extends SearchState {
  final String query;
  final List<PublicUserProfile> userData;

  const SearchResultsLoaded({required this.query, required this.userData});

  @override
  List<Object> get props => [query, userData];
}

class SearchResultsError extends SearchState {
  final String query;
  final String error;

  const SearchResultsError({required this.query, required this.error});

  @override
  List<Object> get props => [query, Future.error(error)];
}
