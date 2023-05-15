import 'package:equatable/equatable.dart';

abstract class UpgradeToPremiumEvent extends Equatable {
  const UpgradeToPremiumEvent();

  @override
  List<Object?> get props => [];
}

class InitiateUpgradeToPremium extends UpgradeToPremiumEvent {

  const InitiateUpgradeToPremium();

  @override
  List<Object?> get props => [];

}