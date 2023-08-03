import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class ShareContentEvent extends Equatable {
  const ShareContentEvent();

  @override
  List<Object?> get props => [];
}

class PostDetailsChanged extends ShareContentEvent {
  final String userId;
  final String text;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const PostDetailsChanged({
    required this.userId,
    required this.text,
    required this.selectedImage,
    required this.selectedImageName,
  } );

  @override
  List<Object?> get props => [userId, text, selectedImage, selectedImageName];
}

class CreateNewPostWithSharedContent extends ShareContentEvent {
  final String userId;
  final String text;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const CreateNewPostWithSharedContent({
    required this.userId,
    required this.text,
    required this.selectedImage,
    required this.selectedImageName,
  } );

  @override
  List<Object?> get props => [userId, text, selectedImage, selectedImageName];
}
