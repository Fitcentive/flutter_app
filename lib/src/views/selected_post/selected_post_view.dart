import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/views/shared_components/liked_users/liked_users_view.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_bloc.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_event.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectedPostView extends StatefulWidget {
  static const String routeName = "view-post";

  final PublicUserProfile currentUserProfile;
  final String currentPostId;
  final SocialPost? currentPost;
  final List<SocialPostComment>? currentPostComments;
  final PostsWithLikedUserIds? likedUsersForCurrentPost;
  final Map<String, PublicUserProfile>? userIdProfileMap;

  // If isMocKDataMode is true, photoURLs are served raw instead of adding public gateway base host to URL
  final bool isMockDataMode;

  const SelectedPostView({
    Key? key,
    required this.currentUserProfile,
    required this.currentPostId,
    this.currentPost,
    this.currentPostComments,
    this.likedUsersForCurrentPost,
    this.userIdProfileMap,
    this.isMockDataMode = false,
  }): super(key: key);

  static Route route({
    required PublicUserProfile currentUserProfile,
    required String currentPostId,
    SocialPost? currentPost,
    List<SocialPostComment>? currentPostComments,
    PostsWithLikedUserIds? likedUsersForCurrentPost,
    Map<String, PublicUserProfile>? userIdProfileMap,
    bool isMockDataMode = false,
  }) => MaterialPageRoute(
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
      child: SelectedPostView(
                currentUserProfile: currentUserProfile,
                currentPostId: currentPostId,
                currentPost: currentPost,
                currentPostComments: currentPostComments,
                likedUsersForCurrentPost: likedUsersForCurrentPost,
                userIdProfileMap: userIdProfileMap,
                isMockDataMode: isMockDataMode,
            ),
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

    if (widget.currentPost != null && widget.currentPostComments != null &&
        widget.likedUsersForCurrentPost != null && widget.userIdProfileMap != null) {
      _selectedPostBloc.add(
          PostAlreadyProvidedByParent(
            currentUserId: widget.currentUserProfile.userId,
            currentPost: widget.currentPost!,
            currentPostComments: widget.currentPostComments!,
            likedUsersForCurrentPost: widget.likedUsersForCurrentPost!,
            userIdProfileMap: widget.userIdProfileMap!,
            isMockDataMode: widget.isMockDataMode,
          )
      );
    }
    else {
      _selectedPostBloc.add(
          FetchSelectedPost(
              postId: widget.currentPostId,
              currentUserId: widget.currentUserProfile.userId,
              isMockDataMode: widget.isMockDataMode,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Post", style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
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
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                  WidgetUtils.spacer(15),
                  WidgetUtils.generatePostImageIfExists(post.photoUrl, widget.isMockDataMode),
                  WidgetUtils.spacer(15),
                  _getLikesAndComments(post, likedUsersForPosts),
                  WidgetUtils.spacer(10),
                  _getPostActionButtons(post, likedUsersForPosts),
                  WidgetUtils.spacer(5),
                  _renderPostCreationTime(post),
                  WidgetUtils.spacer(5),
                  _renderCommentsList(userIdProfileMap),
                  WidgetUtils.spacer(5),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _createAddCommentView(widget.currentUserProfile),
                  )
                ]
            ),
          ),
        ),
      ),
    );
  }

  _onSubmitButtonPressed() {
    if (newUserComment != null && newUserComment!.isNotEmpty) {
      _selectedPostBloc.add(
          AddNewComment(
              postId: widget.currentPostId,
              userId: widget.currentUserProfile.userId,
              comment: newUserComment!,
              isMockDataMode: widget.isMockDataMode
          )
      );
      _textEditingController.text = "";
      setState(() {
        newUserComment = null;
      });
    }
  }

  _createAddCommentView(PublicUserProfile? currentUserProfile) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WidgetUtils.spacer(5),
          CircleAvatar(
            radius: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: ImageUtils.getUserProfileImage(currentUserProfile, 100, 100),
              ),
            ),
          ),
          WidgetUtils.spacer(5),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 7.5, 0, 7.5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: TextField(
                  controller: _textEditingController,
                  textCapitalization: TextCapitalization.sentences,
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
                  maxLines: null,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Share your thoughts here...',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
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

  _goToUserProfile(PublicUserProfile? userProfile) {
    if (userProfile != null) {
      Navigator.pushAndRemoveUntil(
          context,
          UserProfileView.route(userProfile, widget.currentUserProfile),
              (route) => true
      );
    }
  }

  _commentListItem(SocialPostComment comment, PublicUserProfile? userProfile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: ListTile(
        onTap: () {
          KeyboardUtils.hideKeyboard(context);
        },
        leading: InkWell(
          onTap: () {
            _goToUserProfile(userProfile);
          },
          child: CircleAvatar(
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
        ),
        title: Text(
          StringUtils.getUserNameFromUserProfile(userProfile),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _userCommentText(comment),
      ),
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
                // Force conversion as Neo4J db stores only in UTC but agnostically
                timeago.format(comment.createdAt.add(DateTime.now().timeZoneOffset)),
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
                    if (!widget.isMockDataMode) {
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
                    }
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
                    _goToBottom();
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

  _goToBottom() {
    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease
    );
  }

  _showLikedUsers(List<String> userIds) {
    showDialog(context: context, builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.fromLTRB(25, 75, 25, 75),
        child: LikedUsersView.withBloc(widget.currentUserProfile, userIds),
      );
    });
  }

  _getLikesAndComments(SocialPost post, PostsWithLikedUserIds likedUserIds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Visibility(
          visible: likedUserIds.userIds.isNotEmpty,
          child: Container(
            padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: InkWell(
                onTap: () {
                  _showLikedUsers(likedUserIds.userIds);
                },
                child: Text(
                    StringUtils.getNumberOfLikesOnPostText(widget.currentUserProfile.userId, likedUserIds.userIds)
                ),
              )
            ),
          ),
        ),
        Visibility(
          visible: post.numberOfComments != 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 2.5, 0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: InkWell(
                onTap: () {
                  _goToBottom();
                },
                child:  Text("${post.numberOfComments} ${post.numberOfComments == 1 ? "comment" : "comments"}"),
              ),
            ),
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

  _renderPostCreationTime(SocialPost post) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Text(
          // Force conversion as Neo4J db stores only in UTC but agnostically
          timeago.format(post.updatedAt.add(DateTime.now().timeZoneOffset)),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }


}