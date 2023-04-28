import 'package:equatable/equatable.dart';

abstract class CreateUserFitnessProfileEvent extends Equatable {
  const CreateUserFitnessProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpsertUserFitnessProfile extends CreateUserFitnessProfileEvent {
  final String userId;
  final double heightInCm;
  final double weightInLbs;

  const UpsertUserFitnessProfile({
    required this.userId,
    required this.heightInCm,
    required this.weightInLbs,
  });

  @override
  List<Object?> get props => [
    userId,
    heightInCm,
    weightInLbs,
  ];
}
