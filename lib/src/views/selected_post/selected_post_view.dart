import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_bloc.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_event.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class SelectedPostView extends StatefulWidget {
  static const String routeName = "view-post";

  final PublicUserProfile currentUserProfile;
  final String currentPostId;

  const SelectedPostView({
    Key? key,
    required this.currentUserProfile,
    required this.currentPostId,
  }): super(key: key);

  static Route route(PublicUserProfile currentUserProfile, String currentPostId) => MaterialPageRoute(
    settings: const RouteSettings(
        name: routeName
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<SelectedPostBloc>(
            create: (context) => SelectedPostBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: SelectedPostView(currentUserProfile: currentUserProfile, currentPostId: currentPostId),
    ),
  );

  @override
  State createState() {
    return SelectedPostViewState();
  }
}

class SelectedPostViewState extends State<SelectedPostView> {

  late final SelectedPostBloc _selectedPostBloc;

  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PostsWithLikedUserIds likedUsersForPosts = PostsWithLikedUserIds("", List.empty());
  List<SocialPostComment> commentsForPost = List.empty(growable: true);
  String? newUserComment;

  @override
  void initState() {
    super.initState();

    _selectedPostBloc = BlocProvider.of<SelectedPostBloc>(context);
    _selectedPostBloc.add(FetchSelectedPost(postId: widget.currentPostId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Post", style: TextStyle(color: Colors.teal),),
      ),
      body: BlocBuilder<SelectedPostBloc, SelectedPostState>(
        builder: (context, state) {
          if (state is SelectedPostLoaded) {
            likedUsersForPosts = state.postWithLikedUserIds;
            commentsForPost = state.comments;
            return _generatePostView(state);
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

  _generatePostView(SelectedPostLoaded state) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: _renderPostAndComments(state.post, state.userProfileMap),
    );
  }

  Widget _renderPostAndComments(
      SocialPost post,
      Map<String, PublicUserProfile> userIdProfileMap,
  ) {
    final publicUser = userIdProfileMap[post.userId];
    return Container(
      padding: const EdgeInsets.all(10),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls(
                [
                  _userHeader(publicUser),
                  WidgetUtils.spacer(10),
                  _userPostText(post),
                  WidgetUtils.spacer(5),
                  WidgetUtils.generatePostImageIfExists(post.photoUrl),
                  WidgetUtils.spacer(5),
                  _getLikesAndComments(post, likedUsersForPosts),
                  _getPostActionButtons(post, likedUsersForPosts),
                  WidgetUtils.spacer(5),
                  _renderCommentsList(userIdProfileMap),
                  WidgetUtils.spacer(5),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 50, maxHeight: 75),
                      child: _createAddCommentView(),
                    ),
                  )
                ]
            ),
          ),
        ),
      ),
    );
  }

  _addCommentDialog() {
    return GestureDetector(
      onTap: () {
        KeyboardUtils.hideKeyboard(context);
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text("Add Comment", style: TextStyle(color: Colors.teal),),
            ),
            body: Align(
              alignment: Alignment.bottomLeft,
              child: TextField(
                onChanged: (text) {
                  setState(() {
                    if (text.trim().isNotEmpty) {
                      newUserComment = text;
                    }
                    else {
                      newUserComment = null;
                    }
                  });
                },
                decoration: const InputDecoration(
                    hintText: "Write a comment..."
                ),
                controller: _textEditingController,
                expands: true,
                minLines: null,
                maxLines: null,
              ),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              ElevatedButton(
                  onPressed: () {
                    if (_textEditingController.value.text.trim().isEmpty) {
                      newUserComment = null;
                      _textEditingController.text = "";
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel")
              ),
              const Spacer(),
              ElevatedButton(
                  onPressed: () {
                    _onSubmitButtonPressed();
                    Navigator.pop(context);
                  },
                  child: const Text("Post")
              )
            ],
          )
        ],
      ),
    );
  }

  _onSubmitButtonPressed() {
    if (newUserComment != null && newUserComment!.isNotEmpty) {
      _selectedPostBloc.add(
          AddNewComment(
              postId: widget.currentPostId,
              userId: widget.currentUserProfile.userId,
              comment: newUserComment!
          )
      );
      _textEditingController.text = "";
      setState(() {
        newUserComment = null;
      });
    }
  }

  _createAddCommentView() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              showDialog(context: context, builder: (context) {
                return _addCommentDialog();
              });
            },
            child: FittedBox(
              fit:BoxFit.fitHeight,
              child:  Container(
                  width: ScreenUtils.getScreenWidth(context) * 0.6,
                  padding: const EdgeInsets.all(15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      newUserComment ?? "Write a comment...",
                    ),
                  )
              ),
            ),
          ),
          Container(
              padding: const EdgeInsets.all(15),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: () {
                      _onSubmitButtonPressed();
                    },
                    icon: Icon(
                      Icons.send,
                      color: newUserComment == null ? Colors.grey : Colors.teal,
                    )
                ),
              )
          )
        ],
      ),
    );
  }

  _renderCommentsList(Map<String, PublicUserProfile> userIdProfileMap) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: commentsForPost.length,
      itemBuilder: (BuildContext context, int index) {
        if (index >= commentsForPost.length) {
          return const Center(child: CircularProgressIndicator());
        } else {
          final currentComment = commentsForPost[index];
          final userProfile = userIdProfileMap[currentComment.userId];
          return _commentListItem(currentComment, userProfile);
        }
      },
    );
  }

  _commentListItem(SocialPostComment comment, PublicUserProfile? userProfile) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(userProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        StringUtils.getUserNameFromUserProfile(userProfile),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _userCommentText(comment),
    );
  }

  _userCommentText(SocialPostComment comment) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child:  Column(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              comment.text,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              child: Text(
                DateFormat("hh:mm a      yyyy-MM-dd").format(comment.createdAt.add(DateTime.now().timeZoneOffset)),
                style: const TextStyle(
                    fontSize: 10
                ),
              ),
            ),
          )
        ],
      ),
    );
  }


  _userPostText(SocialPost post) {
    return Row(
      children: [
        Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
              child: Text(post.text),
            )
        )
      ],
    );
  }

  _getPostActionButtons(SocialPost post, PostsWithLikedUserIds likedUserIds) {
    return Row(
      children: [
        Expanded(
            child: Container(
              padding: const EdgeInsets.all(2.5),
              child: ElevatedButton.icon(
                  icon: likedUserIds.userIds.contains(widget.currentUserProfile.userId) ?
                  const Icon(Icons.thumb_down) : const Icon(Icons.thumb_up),
                  onPressed: () {
                    List<String> newLikedUserIdsForCurrentPost = likedUserIds.userIds;
                    final hasUserAlreadyLikedPost = newLikedUserIdsForCurrentPost.contains(widget.currentUserProfile.userId);

                    if (hasUserAlreadyLikedPost) {
                      _selectedPostBloc.add(UnlikePostForUser(currentUserId: widget.currentUserProfile.userId, postId: post.postId));
                    } else {
                      _selectedPostBloc.add(LikePostForUser(currentUserId: widget.currentUserProfile.userId, postId: post.postId));
                    }

                    setState(() {
                      if (hasUserAlreadyLikedPost) {
                        newLikedUserIdsForCurrentPost.remove(widget.currentUserProfile.userId);
                      }
                      else {
                        newLikedUserIdsForCurrentPost.add(widget.currentUserProfile.userId);
                      }
                      likedUsersForPosts = PostsWithLikedUserIds(post.postId, newLikedUserIdsForCurrentPost);
                    });
                  },
                  label: Text(likedUserIds.userIds.contains(widget.currentUserProfile.userId) ? "Unlike" : "Like",
                    style: const TextStyle(
                        fontSize: 12
                    ),
                  )
              ),
            )
        ),
        Expanded(
            child: Container(
              padding: const EdgeInsets.all(2.5),
              child: ElevatedButton(
                  onPressed: () {
                    _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease
                    );
                  },
                  child: const Text(
                    "Comment",
                    style: TextStyle(
                        fontSize: 12
                    ),
                  )
              ),
            )
        ),
        Expanded(
            child: Container(
              padding: const EdgeInsets.all(2.5),
              child: ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    "Share",
                    style: TextStyle(
                        fontSize: 12
                    ),
                  )
              ),
            )
        ),
      ],
    );
  }

  _getLikesAndComments(SocialPost post, PostsWithLikedUserIds likedUserIds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(StringUtils.getNumberOfLikesOnPostText(widget.currentUserProfile.userId, likedUserIds.userIds)),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 2.5, 0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Text("${post.numberOfComments} comments"),
          ),
        )
      ],
    );
  }

  _userHeader(PublicUserProfile? publicUser) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(context, UserProfileView.route(publicUser!, widget.currentUserProfile), (route) => true);
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
          StringUtils.getUserNameFromUserProfile(publicUser),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )
      ],
    );
  }

}