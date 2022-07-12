import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_bloc.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_event.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class CommentsListView extends StatefulWidget {

  final String? postId;

  const CommentsListView({Key? key, required this.postId}): super(key: key);

  static Widget withBloc({String? postId, Key? key}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CommentsListBloc>(
            create: (context) => CommentsListBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: CommentsListView(postId: postId, key: key),
    );
  }

  @override
  State createState() {
    return CommentsListViewState();
  }
}

class CommentsListViewState extends State<CommentsListView> {

  late final CommentsListBloc _commentsListBloc;
  late final AuthenticationBloc _authenticationBloc;

  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _commentsListBloc = BlocProvider.of<CommentsListBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    if (widget.postId != null) {
      _commentsListBloc.add(FetchCommentsRequested(postId: widget.postId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "View Comments",
            style: TextStyle(color: Colors.teal),
          )),
      body: BlocBuilder<CommentsListBloc, CommentsListState>(
        builder: (context, state) {
          if (state is CommentsLoaded) {
            // todo - need to fix comments being hidden by keyboard
            // todo - better UI and formatting for comment, more compact? Try ListTile
            return Column(
              children: [
                SizedBox(
                  height: 325,
                  child: _commentsListView(state.comments, state.userIdProfileMap),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _createAddCommentView(),
                )
              ],
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  _createAddCommentView() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 100),
      child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: ScreenUtils.getScreenWidth(context) * 0.75),
                      child: IntrinsicHeight(
                        child: TextField(
                          controller: _textEditingController,
                          decoration: const InputDecoration(
                          hintText: "Write a comment...",
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: ScreenUtils.getScreenWidth(context) * 0.25),
                      child: IconButton(
                        onPressed: () {
                          final currentAuthState = _authenticationBloc.state;
                          if (currentAuthState is AuthSuccessUserUpdateState &&
                              _textEditingController.value.text.isNotEmpty) {
                            _commentsListBloc.add(
                                AddNewComment(
                                    postId: widget.postId!,
                                    userId: currentAuthState.authenticatedUser.user.id,
                                    comment: _textEditingController.value.text
                                )
                            );
                            _textEditingController.text = "";
                          }
                        },
                        icon: const Icon(Icons.send),
                        color: Colors.teal,
                    ),
                  )
                ],
              )
          )
      ),
    );
  }

  _commentsListView(List<SocialPostComment> comments, Map<String, PublicUserProfile> userProfiles) {
    if (comments.isEmpty) {
      return GestureDetector(
        onTap: () {
          KeyboardUtils.hideKeyboard(context);
        },
        child: const Center(
            child: Text("Awfully quiet here....")
        ),
      );
    }
    else {
      return RefreshIndicator(
        onRefresh: () async {
          _commentsListBloc.add(FetchCommentsRequested(postId: widget.postId!));
        },
        child: GestureDetector(
          onTap: () {
            KeyboardUtils.hideKeyboard(context);
          },
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (BuildContext context, int index) {
              if (index >= comments.length) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final currentComment = comments[index];
                final userProfile = userProfiles[currentComment.userId];
                return _commentListItem(currentComment, userProfile);
              }
            },
          ),
        ),

      );
    }
  }

  _commentListItem(SocialPostComment comment, PublicUserProfile? userProfile) {
    return Container(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls(
                [
                  _userHeader(userProfile),
                  WidgetUtils.spacer(10),
                  _userCommentText(comment),
                  _userCommentTime(comment),
                ]
            ),
          ),
        ),
      ),
    );
  }

  _userHeader(PublicUserProfile? publicUser) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(context, UserProfileView.route(publicUser!), (route) => true);
          },
          child: CircleAvatar(
            radius: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: ImageUtils.getUserProfileImage(publicUser, 100, 100),
              ),
            ),
          ),
        ),
        WidgetUtils.spacer(20),
        Text(
          StringUtils.getUserNameFromUserId(publicUser),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  _userCommentText(SocialPostComment comment) {
    return Row(
      children: [
        Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 5),
              child: Text(
                comment.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold
                ),
              ),
            )
        )
      ],
    );
  }

  _userCommentTime(SocialPostComment comment) {
    return Row(
      children: [
        Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
              child: Text(
                DateFormat("hh:mm      yyyy-MM-dd").format(comment.createdAt),
              ),
            )
        )
      ],
    );
  }
}