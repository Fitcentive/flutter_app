import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class CreateNewPostEvent extends Equatable {
  const CreateNewPostEvent();
}

class PostDetailsChanged extends CreateNewPostEvent {
  final String userId;
  final String text;
  final XFile? image;

  const PostDetailsChanged({
    required this.userId,
    required this.text,
    required this.image,
  } );

  @override
  List<Object?> get props => [userId, text, image];
}

class PostSubmitted extends CreateNewPostEvent {
  final String userId;
  final String text;
  final XFile? image;

  const PostSubmitted({
    required this.userId,
    required this.text,
    required this.image,
  });

  @override
  List<Object?> get props => [userId, text, image];
}