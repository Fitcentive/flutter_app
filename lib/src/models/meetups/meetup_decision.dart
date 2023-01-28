import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_decision.g.dart';

@JsonSerializable()
class MeetupDecision extends Equatable {
  final String meetupId;
  final String userId;
  final bool hasAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetupDecision(
      this.meetupId,
      this.userId,
      this.hasAccepted,
      this.createdAt,
      this.updatedAt
  );

  factory MeetupDecision.fromJson(Map<String, dynamic> json) => _$MeetupDecisionFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupDecisionToJson(this);

  @override
  List<Object?> get props => [
    meetupId,
    userId,
    hasAccepted,
    createdAt,
    updatedAt
  ];
}

class MeetupDecisionUpsert extends Equatable {
  final bool hasAccepted;

  const MeetupDecisionUpsert(
      this.hasAccepted,
  );

  @override
  List<Object?> get props => [
    hasAccepted,
  ];
}