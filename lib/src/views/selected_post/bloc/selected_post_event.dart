import 'package:equatable/equatable.dart';

abstract class SelectedPostEvent extends Equatable {

  const SelectedPostEvent();

  @override
  List<Object> get props => [];

}

class FetchSelectedPost extends SelectedPostEvent {
  final String currentUserId;
  final String postId;

  const FetchSelectedPost({
    required this.currentUserId,
    required this.postId,
  });

  @override
  List<Object> get props => [];
}

class LikePostForUser extends SelectedPostEvent {
  final String currentUserId;
  final String postId;

  const LikePostForUser({
    required this.currentUserId,
    required this.postId,
  });

  @override
  List<Object> get props => [postId, currentUserId];
}

class UnlikePostForUser extends SelectedPostEvent {
  final String currentUserId;
  final String postId;

  const UnlikePostForUser({
    required this.currentUserId,
    required this.postId,
  });

  @override
  List<Object> get props => [postId, currentUserId];
}

class AddNewComment extends SelectedPostEvent {
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