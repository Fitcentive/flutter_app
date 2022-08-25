import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_agreements.g.dart';

@JsonSerializable()
class UserAgreements extends Equatable {
  @JsonKey(required: true)
  final String userId;

  @JsonKey(required: true)
  final bool termsAndConditionsAccepted;

  @JsonKey(required: true)
  final bool privacyPolicyAccepted;

  @JsonKey(required: true)
  final bool subscribeToEmails;

  @JsonKey(required: true)
  final DateTime createdAt;

  @JsonKey(required: true)
  final DateTime updatedAt;

  const UserAgreements(
      this.userId,
      this.termsAndConditionsAccepted,
      this.privacyPolicyAccepted,
      this.subscribeToEmails,
      this.createdAt,
      this.updatedAt
  );

  factory UserAgreements.fromJson(Map<String, dynamic> json) => _$UserAgreementsFromJson(json);

  Map<String, dynamic> toJson() => _$UserAgreementsToJson(this);

  @override
  List<Object?> get props => [
    userId,
    termsAndConditionsAccepted,
    privacyPolicyAccepted,
    subscribeToEmails,
    createdAt,
    updatedAt,
  ];
}

class UpdateUserAgreements extends Equatable {
  final bool? termsAndConditionsAccepted;
  final bool? subscribeToEmails;
  final bool? privacyPolicyAccepted;

  const UpdateUserAgreements({
    this.termsAndConditionsAccepted,
    this.privacyPolicyAccepted,
    this.subscribeToEmails
  });

  @override
  List<Object?> get props => [
    termsAndConditionsAccepted,
    privacyPolicyAccepted,
    subscribeToEmails,
  ];
}