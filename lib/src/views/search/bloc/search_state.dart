import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';

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

class UserFitnessProfileFetched extends SearchState {
  final FitnessUserProfile? fitnessUserProfile;

  const UserFitnessProfileFetched({required this.fitnessUserProfile});

  @override
  List<Object?> get props => [fitnessUserProfile];
}
