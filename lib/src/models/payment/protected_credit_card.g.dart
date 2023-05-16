// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protected_credit_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProtectedCreditCard _$ProtectedCreditCardFromJson(Map<String, dynamic> json) =>
    ProtectedCreditCard(
      lastFour: json['lastFour'] as String,
      expiryMonth: json['expiryMonth'] as int,
      expiryYear: json['expiryYear'] as int,
    );

Map<String, dynamic> _$ProtectedCreditCardToJson(
        ProtectedCreditCard instance) =>
    <String, dynamic>{
      'lastFour': instance.lastFour,
      'expiryMonth': instance.expiryMonth,
      'expiryYear': instance.expiryYear,
    };
