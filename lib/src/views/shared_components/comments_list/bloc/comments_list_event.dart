import 'package:equatable/equatable.dart';

abstract class CommentsListEvent extends Equatable {
  const CommentsListEvent();
}

class FetchCommentsRequested extends CommentsListEvent {
  final String postId;

  const FetchCommentsRequested({required this.postId});

  @override
  List<Object> get props => [postId];
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