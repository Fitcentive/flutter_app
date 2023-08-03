import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/social/new_post.dart';
import 'package:formz/formz.dart';

abstract class ShareContentState extends Equatable {
  const ShareContentState();
}

class ShareContentStateInitial extends ShareContentState {
  const ShareContentStateInitial();

  @override
  List<Object?> get props => [];
}

class PostDetailsModified extends ShareContentState {
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

class PostCreatedSuccess extends ShareContentState {

  const PostCreatedSuccess();

  @override
  List<Object?> get props => [];

}
