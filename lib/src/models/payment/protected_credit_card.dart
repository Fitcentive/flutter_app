import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'protected_credit_card.g.dart';

@JsonSerializable()
class ProtectedCreditCard extends Equatable {
  final String lastFour;
  final int expiryMonth;
  final int expiryYear;

  const ProtectedCreditCard({
    required this.lastFour,
    required this.expiryMonth,
    required this.expiryYear
  });

  factory ProtectedCreditCard.fromJson(Map<String, dynamic> json) => _$ProtectedCreditCardFromJson(json);

  Map<String, dynamic> toJson() => _$ProtectedCreditCardToJson(this);

  @override
  List<Object> get props => [
    lastFour,
    expiryMonth,
    expiryYear,
  ];
}