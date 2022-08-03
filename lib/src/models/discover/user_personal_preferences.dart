import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_personal_preferences.g.dart';

@JsonSerializable()
class UserPersonalPreferences extends Equatable {
  final String userId;
  final List<String> gendersInterestedIn;
  final List<String> preferredDays;
  final int minimumAge;
  final int maximumAge;
  final double hoursPerWeek;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPersonalPreferences(
      this.userId,
      this.gendersInterestedIn,
      this.preferredDays,
      this.minimumAge,
      this.maximumAge,
      this.hoursPerWeek,
      this.createdAt,
      this.updatedAt
  );

  factory UserPersonalPreferences.fromJson(Map<String, dynamic> json) => _$UserPersonalPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPersonalPreferencesToJson(this);

  @override
  List<Object?> get props => [
    userId,
    gendersInterestedIn,
    preferredDays,
    minimumAge,
    maximumAge,
    hoursPerWeek,
    createdAt,
    updatedAt,
  ];
}

class UserPersonalPreferencesPost extends Equatable {
  final String userId;
  final List<String> gendersInterestedIn;
  final List<String> preferredDays;
  final int minimumAge;
  final int maximumAge;
  final double hoursPerWeek;

  const UserPersonalPreferencesPost({
    required this.userId,
    required this.gendersInterestedIn,
    required this.preferredDays,
    required this.minimumAge,
    required this.maximumAge,
    required this.hoursPerWeek,
  });

  @override
  List<Object?> get props => [
    userId,
    gendersInterestedIn,
    preferredDays,
    minimumAge,
    maximumAge,
    hoursPerWeek,
  ];

}