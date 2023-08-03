import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/share_content/bloc/share_content_bloc.dart';
import 'package:flutter_app/src/views/share_content/bloc/share_content_event.dart';
import 'package:flutter_app/src/views/share_content/bloc/share_content_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';

class ShareContentView extends StatefulWidget {
  static const String routeName = 'post/share';

  final PublicUserProfile userProfile;
  final String initialText;
  final Widget widgetImage;

  const ShareContentView({Key? key,
    required this.userProfile,
    required this.initialText,
    required this.widgetImage,
  }) : super(key: key);

  static Route route(PublicUserProfile userProfile, String initialText, Widget widgetImage) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) =>
            MultiBlocProvider(
              providers: [
                BlocProvider<ShareContentBloc>(
                    create: (context) => ShareContentBloc(
                      socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
                      userRepository: RepositoryProvider.of<UserRepository>(context),
                      imageRepository: RepositoryProvider.of<PublicGatewayRepository>(context),
                      secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                    )),
              ],
              child: ShareContentView(userProfile: userProfile, initialText: initialText, widgetImage: widgetImage),
            ));
  }

  @override
  State createState() {
    return ShareContentViewState();
  }
}

GlobalKey widgetToCaptureKey = GlobalKey();

class ShareContentViewState extends State<ShareContentView> {

  late final ShareContentBloc _shareContentBloc;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();

    _shareContentBloc = BlocProvider.of<ShareContentBloc>(context);
    _shareContentBloc.add(
        PostDetailsChanged(
            userId: widget.userProfile.userId,
            text: widget.initialText,
            selectedImage: null,
            selectedImageName: null,
        )
    );
  }

  _captureWidgetAndUpdateBloc() async {
    final currentState = _shareContentBloc.state;
    if (currentState is ShareContentStateInitial ||
            (currentState is PostDetailsModified && currentState.selectedImage == null)) {
      screenshotController
          .capture(pixelRatio: MediaQuery.of(context).devicePixelRatio)
          .then((Uint8List? image) {
            if (image != null) {
              const uuid = Uuid();
              _shareContentBloc.add(
                  PostDetailsChanged(
                    userId: widget.userProfile.userId,
                    text: widget.initialText,
                    selectedImage: image,
                    selectedImageName: "share-content-${uuid.v4()}.jpg"
                  )
              );
            }
      }).catchError((onError) {
        print(onError);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureWidgetAndUpdateBloc();
    });
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return BlocListener<ShareContentBloc, ShareContentState>(
        listener: (context, state) {
          if (state is PostCreatedSuccess) {
            SnackbarUtils.showSnackBarShort(context, "Post shared successfully!");
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
          appBar: AppBar(
            title: const Text(
                "Share Post",
                style: TextStyle(color: Colors.teal)
            ),
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            // actions: <Widget>[
            //   Container(
            //     padding: const EdgeInsets.all(10),
            //     child: ElevatedButton(
            //       onPressed: () {
            //         _submitPost();
            //       },
            //       child: const Text("Post"),
            //     ),
            //   )
            // ],
          ),
          body: BlocBuilder<ShareContentBloc, ShareContentState>(builder: (context, state) {
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

  _submitPost() {
    final state = _shareContentBloc.state;
    if (state is PostDetailsModified && state.status.isValid) {
      _shareContentBloc.add(
          CreateNewPostWithSharedContent(
              userId: state.userId,
              text: state.text.value,
              selectedImage: state.selectedImage,
              selectedImageName: state.selectedImageName
          )
      );
    }
    else {
      SnackbarUtils.showSnackBarShort(context, "Please complete the required fields!");
    }
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
                      height: 150,
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 50),
                        child: IntrinsicHeight(
                          child: TextFormField(
                            initialValue: widget.initialText,
                            decoration: InputDecoration(
                              hintStyle: const TextStyle(color: Colors.grey),
                              errorText: state.text.invalid ? 'This cannot be left blank' : null,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (text)  {
                              _shareContentBloc.add(
                                  PostDetailsChanged(
                                    userId: state.userId,
                                    text: text,
                                    selectedImage: state.selectedImage,
                                    selectedImageName: state.selectedImageName,
                                  )
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
            _generatePostImageWidget(state),
            WidgetUtils.spacer(5),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                    ),
                    onPressed: () async {
                      SnackbarUtils.showSnackBarShort(context, "Hang on while we upload your post...");
                      _submitPost();
                    },
                    child: const Text(
                        "Post",
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white
                        )),
                  ),
                ),
              ],
            )
          ]),
        ),
      ),
    );
  }

  Widget? _generatePostImageWidget(PostDetailsModified state) {
    return Row(
      children: [
        Expanded(
            child: Screenshot(
              controller: screenshotController,
              child:  Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    side: const BorderSide(
                        color: Colors.teal,
                        width: 1
                    )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: widget.widgetImage,
                ),
              )
            )
        ),
      ],
    );
  }

}