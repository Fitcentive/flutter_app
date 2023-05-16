import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class UpgradeToPremiumEvent extends Equatable {
  const UpgradeToPremiumEvent();

  @override
  List<Object?> get props => [];
}

class InitiateUpgradeToPremium extends UpgradeToPremiumEvent {
  final AuthenticatedUser user;
  final String paymentMethodId;

  const InitiateUpgradeToPremium({
    required this.paymentMethodId,
    required this.user,
  });

  @override
  List<Object?> get props => [paymentMethodId, user];

}