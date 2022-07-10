import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/image_repository.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/views/create_new_post/bloc/create_new_post_event.dart';
import 'package:flutter_app/src/views/create_new_post/bloc/create_new_post_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateNewPostBloc extends Bloc<CreateNewPostEvent, CreateNewPostState> {
  final SocialMediaRepository socialMediaRepository;
  final ImageRepository imageRepository;
  final FlutterSecureStorage secureStorage;

  CreateNewPostBloc({
    required this.socialMediaRepository,
    required this.imageRepository,
    required this.secureStorage
  }): super(const CreateNewPostInitialState()) {
    on<PostDetailsChanged>(_postDetailsChanged);
    on<PostSubmitted>(_postSubmitted);
  }

  void _postDetailsChanged(PostDetailsChanged event, Emitter<CreateNewPostState> emit) async {
    emit(PostDetailsModified(userId: event.userId, text: event.text, image: event.image));
  }

  void _postSubmitted(PostSubmitted event, Emitter<CreateNewPostState> emit) async {
    try {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      String? postPhotoUrl;
      if (event.image != null) {
        final fileName = event.image!.path.split("/").last;
        final filePath = "users/${event.userId}/social-posts/$fileName";
        postPhotoUrl = await imageRepository.uploadImage(filePath, event.image!, accessToken!);
      }
      final newPost = SocialPostCreate(userId: event.userId, text: event.text, photoUrl: postPhotoUrl);
      await socialMediaRepository.createPostForUser(event.userId, newPost, accessToken!);
      emit(const PostSubmittedSuccessfully());
    } catch (e) {
      emit(PostSubmissionFailure(error: e.toString()));
    }
  }
}