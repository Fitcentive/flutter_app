import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class ManagePremiumEvent extends Equatable {
  const ManagePremiumEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserPremiumSubscription extends ManagePremiumEvent {
  final AuthenticatedUser user;

  const FetchUserPremiumSubscription({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class CancelPremium extends ManagePremiumEvent {
  final AuthenticatedUser user;

  const CancelPremium({
    required this.user,
  });

  @override
  List<Object?> get props => [user];

}