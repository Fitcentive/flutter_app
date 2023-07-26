import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_subscription.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PaymentSubscription extends Equatable {
  final String id;
  final String userId;
  final String subscriptionId;
  final String customerId;
  final DateTime startedAt;
  final DateTime validUntil;
  final DateTime? trialEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentSubscription(
      this.id,
      this.userId,
      this.subscriptionId,
      this.customerId,
      this.startedAt,
      this.validUntil,
      this.trialEnd,
      this.createdAt,
      this.updatedAt
  );

  factory PaymentSubscription.fromJson(Map<String, dynamic> json) => _$PaymentSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSubscriptionToJson(this);

  @override
  List<Object?> get props => [id, userId, subscriptionId, customerId, startedAt, validUntil, createdAt, updatedAt];
}