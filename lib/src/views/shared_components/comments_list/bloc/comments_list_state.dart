import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';

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
  final String userId;
  final List<SocialPostComment> comments;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const CommentsLoaded({required this.userId, required this.comments, required this.userIdProfileMap});

  @override
  List<Object> get props => [userId, comments, userIdProfileMap];
}