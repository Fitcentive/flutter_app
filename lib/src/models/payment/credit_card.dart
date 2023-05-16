import 'package:equatable/equatable.dart';

class CreditCard extends Equatable {
  final String cardNumber;
  final String cvc;
  final int expiryMonth;
  final int expiryYear;

  const CreditCard({
    required this.cardNumber,
    required this.cvc,
    required this.expiryMonth,
    required this.expiryYear
  });

  @override
  List<Object> get props => [
    cardNumber,
    cvc,
    expiryMonth,
    expiryYear,
  ];
}