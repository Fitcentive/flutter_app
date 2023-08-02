import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';

abstract class UserFitnessProfileState extends Equatable {
  const UserFitnessProfileState();

  @override
  List<Object?> get props => [];
}

class UserFitnessProfileStateInitial extends UserFitnessProfileState {

  const UserFitnessProfileStateInitial();
}

class UserFitnessProfileUpserted extends UserFitnessProfileState {
  final FitnessUserProfile fitnessUserProfile;

  const UserFitnessProfileUpserted({
    required this.fitnessUserProfile
  });

  @override
  List<Object?> get props => [fitnessUserProfile];
}

class UserFitnessProfileBeingSaved extends UserFitnessProfileState {

  const UserFitnessProfileBeingSaved();
}