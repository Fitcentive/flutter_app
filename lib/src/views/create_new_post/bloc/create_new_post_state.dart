import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/social/new_post.dart';
import 'package:formz/formz.dart';
import 'package:image_picker/image_picker.dart';

abstract class CreateNewPostState extends Equatable {
  const CreateNewPostState();
}

class CreateNewPostInitialState extends CreateNewPostState {
  const CreateNewPostInitialState();

  @override
  List<Object?> get props => [];
}

class PostDetailsModified extends CreateNewPostState {
  final String userId;
  final NewPost text;
  final FormzStatus status;
  final XFile? image;

  PostDetailsModified copyWith({
    FormzStatus? status,
    NewPost? text,
    XFile? image,
  }) {
    return PostDetailsModified(
      status: status ?? this.status,
      text: text ?? this.text,
      image: image ?? this.image,
      userId: userId
    );
  }

  const PostDetailsModified({
    required this.userId,
    required this.text,
    required this.image,
    required this.status
  } );

  @override
  List<Object?> get props => [userId, text, image];
}

class PostSubmittedSuccessfully extends CreateNewPostState {
  const PostSubmittedSuccessfully();

  @override
  List<Object?> get props => [];
}

class PostSubmissionFailure extends CreateNewPostState {
  final String error;

  const PostSubmissionFailure({required this.error});

  @override
  List<Object?> get props => [error];
}