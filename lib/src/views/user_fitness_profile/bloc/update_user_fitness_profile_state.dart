import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';

abstract class CreateUserFitnessProfileState extends Equatable {
  const CreateUserFitnessProfileState();

  @override
  List<Object?> get props => [];
}

class CreateUserFitnessProfileStateInitial extends CreateUserFitnessProfileState {

  const CreateUserFitnessProfileStateInitial();
}

class UserFitnessProfileUpserted extends CreateUserFitnessProfileState {
  final FitnessUserProfile fitnessUserProfile;

  const UserFitnessProfileUpserted({
    required this.fitnessUserProfile
  });

  @override
  List<Object?> get props => [fitnessUserProfile];
}


