import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fitness_user_profile.g.dart';

@JsonSerializable()
class FitnessUserProfile extends Equatable {
  @JsonKey(required: true)
  final String userId;

  final double heightInCm;
  final double weightInLbs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FitnessUserProfile(
      this.userId,
      this.heightInCm,
      this.weightInLbs,
      this.createdAt,
      this.updatedAt,
      );

  factory FitnessUserProfile.fromJson(Map<String, dynamic> json) => _$FitnessUserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessUserProfileToJson(this);

  @override
  List<Object?> get props => [
    userId,
    heightInCm,
    weightInLbs,
    createdAt,
    updatedAt,
  ];
}

class FitnessUserProfileUpdate {
  final double heightInCm;
  final double weightInLbs;

  const FitnessUserProfileUpdate({
    required this.heightInCm,
    required this.weightInLbs
  });
}