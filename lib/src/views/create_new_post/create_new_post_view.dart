import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/image_repository.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/dialog_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_post/bloc/create_new_post_bloc.dart';
import 'package:flutter_app/src/views/create_new_post/bloc/create_new_post_event.dart';
import 'package:flutter_app/src/views/create_new_post/bloc/create_new_post_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';
import 'package:image_picker/image_picker.dart';

class CreateNewPostView extends StatefulWidget {

  final PublicUserProfile userProfile;

  const CreateNewPostView({Key? key, required this.userProfile}) : super(key: key);

  static Route route(PublicUserProfile userProfile) {
    return MaterialPageRoute<void>(
        builder: (_) =>
            MultiBlocProvider(
              providers: [
                BlocProvider<CreateNewPostBloc>(
                    create: (context) => CreateNewPostBloc(
                      socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
                      imageRepository: RepositoryProvider.of<ImageRepository>(context),
                      secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                    )),
              ],
              child: CreateNewPostView(userProfile: userProfile),
            ));
  }

  @override
  State createState() {
    return CreateNewPostViewState();
  }
}

class CreateNewPostViewState extends State<CreateNewPostView> {

  late final CreateNewPostBloc _createNewPostBloc;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _createNewPostBloc = BlocProvider.of<CreateNewPostBloc>(context);
    _createNewPostBloc.add(
        PostDetailsChanged(userId: widget.userProfile.userId, text: "", image: null)
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateNewPostBloc, CreateNewPostState>(
        listener: (context, state) {
          if (state is PostSubmittedSuccessfully) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
                "Create Post",
                style: TextStyle(color: Colors.teal)
            ),
            actions: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: () {
                    // todo - like button working, add likers as part of post response directly (wont scale)
                    // todo - comment button, think about scaling strategy again
                    final state = _createNewPostBloc.state;
                    if (state is PostDetailsModified && state.status.isValid) {
                      _createNewPostBloc.add(
                          PostSubmitted(
                              userId: state.userId,
                              text: state.text.value,
                              image: state.image
                          )
                      );
                    }
                  },
                  child: const Text("Post"),
                ),
              )
            ],
          ),
          body: BlocBuilder<CreateNewPostBloc, CreateNewPostState>(builder: (context, state) {
            if (state is PostDetailsModified) {
              return SingleChildScrollView(
                child: _buildCreatePostPage(state),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              );
            }
          }),
        )
    );
  }

  _buildCreatePostPage(PostDetailsModified state) {
    return GestureDetector(
      onTap: () {
        KeyboardUtils.hideKeyboard(context);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: WidgetUtils.skipNulls([
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: ImageUtils.getUserProfileImage(widget.userProfile, 100, 100),
                    ),
                  ),
                ),
                WidgetUtils.spacer(10),
                Text(
                  "${widget.userProfile.firstName} ${widget.userProfile.lastName}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 50),
                        child: IntrinsicHeight(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "What's on your mind?",
                              errorText: state.text.invalid ? 'This cannot be left blank' : null,
                            ),
                            onChanged: (text)  {
                              _createNewPostBloc.add(
                                  PostDetailsChanged(userId: state.userId, text: text, image: state.image)
                              );
                            } ,
                            maxLines: 10,
                          ),
                        ),
                      ),
                    )
                )
              ],
            ),
            _generatePostImageIfPresent(state),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final imageSource = await showDialog(context: context, builder: (context) {
                        return DialogUtils.showImageSourceSimpleDialog(context);
                      });
                      if (imageSource != null) {
                        final XFile? image = await _picker.pickImage(source: imageSource);
                        _createNewPostBloc.add(
                            PostDetailsChanged(userId: state.userId, text: state.text.value, image: image)
                        );
                      }
                    },
                    child: const Text("Add an image"),
                  ),
                )
              ],
            )
          ]),
        ),
      ),
    );
  }

  Widget? _generatePostImageIfPresent(PostDetailsModified state) {
    if (state.image != null) {
      return Row(
        children: [
          Expanded(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                          image: FileImage(File(state.image!.path)),
                          fit: BoxFit.fitHeight
                      ),
                    ),
                  ),
                  _deleteImageCrossButton(state)
                ],
              )
          ),

        ],
      );
    }
    return null;
  }

  _deleteImageCrossButton(PostDetailsModified state) {
    return GestureDetector(
      onTap: () {
        _createNewPostBloc.add(PostDetailsChanged(
          userId: state.userId,
          text: state.text.value,
          image: null
        ));
      },
      child: Align(
        alignment: const Alignment(1, -1),
        child: Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.teal),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

}