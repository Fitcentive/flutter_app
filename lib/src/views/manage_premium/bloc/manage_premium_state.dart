import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/payment/payment_subscription.dart';
import 'package:flutter_app/src/models/payment/protected_credit_card.dart';

abstract class ManagePremiumState extends Equatable {
  const ManagePremiumState();

  @override
  List<Object?> get props => [];
}

class ManagePremiumStateInitial extends ManagePremiumState {

  const ManagePremiumStateInitial();
}

class SubscriptionInfoLoading extends ManagePremiumState {

  const SubscriptionInfoLoading();
}

class SubscriptionInfoLoaded extends ManagePremiumState {
  final PaymentSubscription subscription;
  final List<ProtectedCreditCard> cards;

  const SubscriptionInfoLoaded({
    required this.subscription,
    required this.cards,
  });

  @override
  List<Object?> get props => [subscription, cards];
}

class CardDeletedSuccessfully extends ManagePremiumState {

  const CardDeletedSuccessfully();
}

class CardAddedSuccessfully extends ManagePremiumState {

  const CardAddedSuccessfully();
}

class CardAddFailure extends ManagePremiumState {

  const CardAddFailure();
}


class CancelLoading extends ManagePremiumState {

  const CancelLoading();
}

class CancelPremiumComplete extends ManagePremiumState {

  const CancelPremiumComplete();
}

