// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerPaymentMethod _$CustomerPaymentMethodFromJson(
        Map<String, dynamic> json) =>
    CustomerPaymentMethod(
      json['userId'] as String,
      json['customerId'] as String,
      json['paymentMethodId'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CustomerPaymentMethodToJson(
        CustomerPaymentMethod instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'customerId': instance.customerId,
      'paymentMethodId': instance.paymentMethodId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
