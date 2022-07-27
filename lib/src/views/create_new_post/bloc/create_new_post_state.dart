import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/social/new_post.dart';
import 'package:formz/formz.dart';

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
  final Uint8List? selectedImage;
  final String? selectedImageName;

  PostDetailsModified copyWith({
    FormzStatus? status,
    NewPost? text,
    required Uint8List? selectedImage,
    required String? selectedImageName,
  }) {
    return PostDetailsModified(
      status: status ?? this.status,
      text: text ?? this.text,
      selectedImage: selectedImage,
      selectedImageName: selectedImageName,
      userId: userId
    );
  }

  const PostDetailsModified({
    required this.userId,
    required this.text,
    required this.selectedImage,
    required this.selectedImageName,
    required this.status
  } );

  @override
  List<Object?> get props => [userId, text, selectedImage, selectedImageName];
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