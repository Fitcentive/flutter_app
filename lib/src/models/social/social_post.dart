import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_post.g.dart';

@JsonSerializable()
class SocialPost extends Equatable {
  final String postId;
  final String userId;
  final String text;
  final String? photoUrl;
  final int numberOfLikes;
  final int numberOfComments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialPost(
     this.postId,
     this.userId,
     this.text,
     this.photoUrl,
     this.numberOfLikes,
     this.numberOfComments,
     this.createdAt,
     this.updatedAt
  );

  @override
  List<Object?> get props => [
    postId,
    userId,
    text,
    photoUrl,
    numberOfLikes,
    numberOfComments,
    createdAt,
    updatedAt,
  ];

  factory SocialPost.fromJson(Map<String, dynamic> json) => _$SocialPostFromJson(json);

  Map<String, dynamic> toJson() => _$SocialPostToJson(this);
}

class SocialPostCreate extends Equatable {
  final String userId;
  final String text;
  final String? photoUrl;

  const SocialPostCreate({required this.userId, required this.text, required this.photoUrl});

  @override
  List<Object?> get props => [
    userId,
    text,
    photoUrl,
  ];

}


