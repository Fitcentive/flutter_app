import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'posts_with_liked_user_ids.g.dart';

@JsonSerializable()
class PostsWithLikedUserIds extends Equatable {
  final String postId;
  final List<String> userIds;

  const PostsWithLikedUserIds(this.postId, this.userIds);

  @override
  List<Object?> get props => [postId, userIds];

  factory PostsWithLikedUserIds.fromJson(Map<String, dynamic> json) => _$PostsWithLikedUserIdsFromJson(json);

  Map<String, dynamic> toJson() => _$PostsWithLikedUserIdsToJson(this);
}

