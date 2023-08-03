import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:uuid/uuid.dart';

abstract class SelectedPostState extends Equatable {

  const SelectedPostState();

  @override
  List<Object> get props => [];

}

class SelectedPostStateInitial extends SelectedPostState {

  const SelectedPostStateInitial();

  @override
  List<Object> get props => [];
}

class SelectedPostLoading extends SelectedPostState {

  const SelectedPostLoading();

  @override
  List<Object> get props => [];
}

class SelectedPostLoaded extends SelectedPostState {
  final uuid = const Uuid();

  final SocialPost post;
  final List<SocialPostComment> comments;
  final PostsWithLikedUserIds postWithLikedUserIds;
  final Map<String, PublicUserProfile> userProfileMap;

  const SelectedPostLoaded({
    required this.post,
    required this.comments,
    required this.postWithLikedUserIds,
    required this.userProfileMap,
  });

  SelectedPostLoaded copyWithNewCommentAdded({
    required String userId,
    required String newComment
  }) {
    final now = DateTime.now().subtract(DateTime.now().timeZoneOffset);
    return SelectedPostLoaded(
        post: post,
        userProfileMap: userProfileMap,
        postWithLikedUserIds: postWithLikedUserIds,
        comments: [...comments, SocialPostComment(post.postId, uuid.v4(), userId, newComment, now, now)]
    );
  }

  @override
  List<Object> get props => [post, comments, postWithLikedUserIds, userProfileMap];
}

class SelectedPostBeingDeleted extends SelectedPostState {

  const SelectedPostBeingDeleted();

  @override
  List<Object> get props => [];
}

class SelectedPostDeleted extends SelectedPostState {

  const SelectedPostDeleted();

  @override
  List<Object> get props => [];
}
