import 'package:equatable/equatable.dart';

abstract class CommentsListEvent extends Equatable {
  const CommentsListEvent();
}

class FetchCommentsRequested extends CommentsListEvent {
  final String postId;
  final String currentUserId;

  const FetchCommentsRequested({required this.postId, required this.currentUserId});

  @override
  List<Object> get props => [postId, currentUserId];
}

class AddNewComment extends CommentsListEvent {
  final String postId;
  final String userId;
  final String comment;

  const AddNewComment({
    required this.postId,
    required this.userId,
    required this.comment,
  });

  @override
  List<Object> get props => [comment, postId, comment];
}