import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_post_comment.g.dart';

@JsonSerializable()
class SocialPostComment extends Equatable {
  final String postId;
  final String commentId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialPostComment(this.postId, this.commentId, this.userId, this.text, this.createdAt, this.updatedAt);

  @override
  List<Object?> get props => [
    postId,
    commentId,
    userId,
    text,
    createdAt,
    updatedAt,
  ];

  factory SocialPostComment.fromJson(Map<String, dynamic> json) => _$SocialPostCommentFromJson(json);

  Map<String, dynamic> toJson() => _$SocialPostCommentToJson(this);

}