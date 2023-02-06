import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_comment.g.dart';

@JsonSerializable()
class MeetupComment extends Equatable {
  final String id;
  final String meetupId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;


  const MeetupComment(this.id, this.meetupId, this.userId, this.comment, this.createdAt, this.updatedAt);

  factory MeetupComment.fromJson(Map<String, dynamic> json) => _$MeetupCommentFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupCommentToJson(this);

  @override
  List<Object?> get props => [
    id,
    meetupId,
    userId,
    comment,
    createdAt,
    updatedAt,
  ];
}
