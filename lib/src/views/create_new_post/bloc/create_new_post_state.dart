import 'package:equatable/equatable.dart';
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
  final String text;
  final XFile? image;

  const PostDetailsModified({
    required this.userId,
    required this.text,
    required this.image,
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