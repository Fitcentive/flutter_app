import 'package:equatable/equatable.dart';

abstract class UserFitnessProfileEvent extends Equatable {
  const UserFitnessProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpsertUserFitnessProfile extends UserFitnessProfileEvent {
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
