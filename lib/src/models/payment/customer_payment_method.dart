import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_payment_method.g.dart';

@JsonSerializable()
class CustomerPaymentMethod extends Equatable {
  final String userId;
  final String customerId;
  final String paymentMethodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerPaymentMethod(
      this.userId,
      this.customerId,
      this.paymentMethodId,
      this.createdAt,
      this.updatedAt
  );

  factory CustomerPaymentMethod.fromJson(Map<String, dynamic> json) => _$CustomerPaymentMethodFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerPaymentMethodToJson(this);

  @override
  List<Object?> get props => [userId, customerId, paymentMethodId, createdAt, updatedAt];
}