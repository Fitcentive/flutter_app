import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_bloc.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_event.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  void initState() {
    super.initState();

    _commentsListBloc = BlocProvider.of<CommentsListBloc>(context);
    if (widget.postId != null) {
      _commentsListBloc.add(FetchCommentsRequested(postId: widget.postId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "View Comments",
            style: TextStyle(color: Colors.teal),
          )),
      body: BlocBuilder<CommentsListBloc, CommentsListState>(
        builder: (context, state) {
          if (state is CommentsLoaded) {
            return _commentsListView(state.comments, state.userIdProfileMap);
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

  _commentsListView(List<SocialPostComment> comments, Map<String, PublicUserProfile> userProfiles) {
    if (comments.isEmpty) {
      return const Center(
          child: Text("Awfully quiet here....")
      );
    }
    else {
      return RefreshIndicator(
        onRefresh: () async {
          _commentsListBloc.add(FetchCommentsRequested(postId: widget.postId!));
        },
        child: ListView.builder(
          itemCount: comments.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index >= comments.length) {
              return const Center(child: CircularProgressIndicator());
            } else {
              final currentComment = comments[index];
              final userProfile = userProfiles[currentComment];
              return _commentListItem(currentComment, userProfile);
            }
          },
        ),
      );
    }
  }

  _commentListItem(SocialPostComment comment, PublicUserProfile? userProfile) {
    return Container(
      padding: const EdgeInsets.all(10),
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
              padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
              child: Text(comment.text),
            )
        )
      ],
    );
  }
}