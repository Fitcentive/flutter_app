// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_agreements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAgreements _$UserAgreementsFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'userId',
      'termsAndConditionsAccepted',
      'privacyPolicyAccepted',
      'subscribeToEmails',
      'createdAt',
      'updatedAt'
    ],
  );
  return UserAgreements(
    json['userId'] as String,
    json['termsAndConditionsAccepted'] as bool,
    json['privacyPolicyAccepted'] as bool,
    json['subscribeToEmails'] as bool,
    DateTime.parse(json['createdAt'] as String),
    DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$UserAgreementsToJson(UserAgreements instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'termsAndConditionsAccepted': instance.termsAndConditionsAccepted,
      'privacyPolicyAccepted': instance.privacyPolicyAccepted,
      'subscribeToEmails': instance.subscribeToEmails,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
