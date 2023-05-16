// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSubscription _$PaymentSubscriptionFromJson(Map<String, dynamic> json) =>
    PaymentSubscription(
      json['id'] as String,
      json['user_id'] as String,
      json['subscription_id'] as String,
      json['customer_id'] as String,
      DateTime.parse(json['started_at'] as String),
      DateTime.parse(json['valid_until'] as String),
      DateTime.parse(json['created_at'] as String),
      DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PaymentSubscriptionToJson(
        PaymentSubscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subscription_id': instance.subscriptionId,
      'customer_id': instance.customerId,
      'started_at': instance.startedAt.toIso8601String(),
      'valid_until': instance.validUntil.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
