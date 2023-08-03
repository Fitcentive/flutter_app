import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/models/social/new_post.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/share_content/bloc/share_content_event.dart';
import 'package:flutter_app/src/views/share_content/bloc/share_content_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';

class ShareContentBloc extends Bloc<ShareContentEvent, ShareContentState> {
  final SocialMediaRepository socialMediaRepository;
  final UserRepository userRepository;
  final PublicGatewayRepository imageRepository;
  final FlutterSecureStorage secureStorage;

  bool isFirstTime = true;

  ShareContentBloc({
    required this.socialMediaRepository,
    required this.userRepository,
    required this.imageRepository,
    required this.secureStorage
  }): super(const ShareContentStateInitial()) {
    on<CreateNewPostWithSharedContent>(_createNewPostWithSharedContent);
    on<PostDetailsChanged>(_postDetailsChanged);
  }

  void _postDetailsChanged(PostDetailsChanged event, Emitter<ShareContentState> emit) async {
    if (isFirstTime) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      userRepository.trackUserEvent(UserAttemptedSharingMilestone(), accessToken!);
      isFirstTime = false;
    }
    final newPostText = NewPost.dirty(event.text);
    final currentState = state;
    if (currentState is PostDetailsModified) {
      emit(currentState.copyWith(
        status: Formz.validate([newPostText]),
        text: newPostText,
        selectedImage: event.selectedImage,
        selectedImageName: event.selectedImageName,
      ));
    }
    else if (currentState is ShareContentStateInitial) {
      final newPost = NewPost.dirty(event.text);
      emit(PostDetailsModified(
          userId: event.userId,
          text: newPost,
          selectedImage: event.selectedImage,
          selectedImageName: event.selectedImageName,
          status: FormzStatus.valid
      ));
    }
  }

  void _createNewPostWithSharedContent(CreateNewPostWithSharedContent event, Emitter<ShareContentState> emit) async {
    try {
      emit(const PostBeingCreated());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      String? postPhotoUrl;
      if (event.selectedImage != null) {
        final filePath = "users/${event.userId}/social-posts/${event.selectedImageName}";
        postPhotoUrl = await imageRepository.uploadImage(filePath, event.selectedImage!, accessToken!);
      }
      final newPost = SocialPostCreate(userId: event.userId, text: event.text, photoUrl: postPhotoUrl);
      await socialMediaRepository.createPostForUser(event.userId, newPost, accessToken!);
      userRepository.trackUserEvent(UserSharedMilestone(), accessToken);
      emit(const PostCreatedSuccess());
    } catch (e) {
      print("Error occurred: $e");
    }
  }

}