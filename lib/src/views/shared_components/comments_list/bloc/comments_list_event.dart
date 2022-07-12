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