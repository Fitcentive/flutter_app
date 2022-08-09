import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:uuid/uuid.dart';

abstract class CommentsListState extends Equatable {
  const CommentsListState();
}

class CommentsListStateInitial extends CommentsListState {
  const CommentsListStateInitial();

  @override
  List<Object> get props => [];
}

class CommentsLoading extends CommentsListState {
  final String userId;

  const CommentsLoading({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CommentsLoaded extends CommentsListState {
  final uuid = const Uuid();
  final String postId;
  final List<SocialPostComment> comments;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const CommentsLoaded({
    required this.postId,
    required this.comments,
    required this.userIdProfileMap
  });

  CommentsLoaded copyWithNewCommentAdded({
    required String userId,
    required String newComment
  }) {
    final now = DateTime.now().toUtc();
    comments.add(SocialPostComment(postId, uuid.v4(), userId, newComment, now, now));
    return CommentsLoaded(
        postId: postId,
        userIdProfileMap: userIdProfileMap,
        comments: comments
    );
  }

  @override
  List<Object> get props => [postId, comments, userIdProfileMap];
}