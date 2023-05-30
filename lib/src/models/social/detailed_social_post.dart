import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:json_annotation/json_annotation.dart';

part 'detailed_social_post.g.dart';

@JsonSerializable()
class DetailedSocialPost extends Equatable {
  final SocialPost post;
  final List<String> likedUserIds;
  final List<SocialPostComment> mostRecentComments;


  const DetailedSocialPost(
      this.post,
      this.likedUserIds,
      this.mostRecentComments
  );

  factory DetailedSocialPost.fromJson(Map<String, dynamic> json) => _$DetailedSocialPostFromJson(json);

  Map<String, dynamic> toJson() => _$DetailedSocialPostToJson(this);

  @override
  List<Object?> get props => [
    post,
    likedUserIds,
    mostRecentComments
  ];
}