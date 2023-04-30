import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class UserSearchState extends Equatable {
  const UserSearchState();

  @override
  List<Object?> get props => [];
}

class UserSearchStateInitial extends UserSearchState {

  const UserSearchStateInitial();

  @override
  List<Object> get props => [];
}

class UserSearchQueryModified extends UserSearchState {
  final String query;

  const UserSearchQueryModified({required this.query});

  @override
  List<Object> get props => [query];
}

class UserSearchResultsLoading extends UserSearchState {
  final String query;

  const UserSearchResultsLoading({required this.query});

  @override
  List<Object> get props => [query];
}

class UserSearchResultsLoaded extends UserSearchState {
  final String query;
  final List<PublicUserProfile> userData;
  final bool doesNextPageExist;

  const UserSearchResultsLoaded({
    required this.query,
    required this.userData,
    required this.doesNextPageExist,
  });

  @override
  List<Object> get props => [query, userData, doesNextPageExist];
}

class UserSearchResultsError extends UserSearchState {
  final String query;
  final String error;

  const UserSearchResultsError({required this.query, required this.error});

  @override
  List<Object> get props => [query, error];
}
