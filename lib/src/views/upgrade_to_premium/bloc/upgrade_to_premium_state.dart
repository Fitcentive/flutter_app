import 'package:equatable/equatable.dart';

abstract class UpgradeToPremiumState extends Equatable {
  const UpgradeToPremiumState();

  @override
  List<Object?> get props => [];
}

class UpgradeToPremiumStateInitial extends UpgradeToPremiumState {

  const UpgradeToPremiumStateInitial();
}

class UpgradeLoading extends UpgradeToPremiumState {

  const UpgradeLoading();
}

class UpgradeToPremiumComplete extends UpgradeToPremiumState {

  const UpgradeToPremiumComplete();
}


class UpgradeToPremiumFailure extends UpgradeToPremiumState {
  final String reason;

  const UpgradeToPremiumFailure({required this.reason});

  @override
  List<Object?> get props => [reason];
}

