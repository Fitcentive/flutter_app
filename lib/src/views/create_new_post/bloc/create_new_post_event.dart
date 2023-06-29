import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class CreateNewPostEvent extends Equatable {
  const CreateNewPostEvent();
}

class PostDetailsChanged extends CreateNewPostEvent {
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

class PostSubmitted extends CreateNewPostEvent {
  final String userId;
  final String text;
  final Uint8List? selectedImage;
  final String? selectedImageName;

  const PostSubmitted({
    required this.userId,
    required this.text,
    required this.selectedImage,
    required this.selectedImageName,
  });

  @override
  List<Object?> get props => [userId, text, selectedImage, selectedImageName];
}

class TrackAttemptToCreatePostEvent extends CreateNewPostEvent {

  const TrackAttemptToCreatePostEvent();

  @override
  List<Object?> get props => [];
}