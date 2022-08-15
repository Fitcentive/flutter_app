import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/selected_post/selected_post_view.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';

typedef ButtonInteractionCallback = void Function(SocialPost post, PostsWithLikedUserIds likedUserIds);

class SocialPostsList extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final List<SocialPost> posts;
  final Map<String, PublicUserProfile> userIdProfileMap;
  final Map<String, List<SocialPostComment>> postIdCommentsMap;
  final List<PostsWithLikedUserIds> likedUserIds;
  final bool doesNextPageExist;

  final FetchMoreResultsCallback fetchMoreResultsCallback;
  final FetchMoreResultsCallback refreshCallback;
  final ButtonInteractionCallback buttonInteractionCallback;

  const SocialPostsList({
    Key? key,
    required this.currentUserProfile,
    required this.posts,
    required this.userIdProfileMap,
    required this.likedUserIds,
    required this.doesNextPageExist,
    required this.fetchMoreResultsCallback,
    required this.refreshCallback,
    required this.buttonInteractionCallback,
    required this.postIdCommentsMap,
  }): super(key: key);

  @override
  State createState() {
    return SocialPostsListState();
  }
}

class SocialPostsListState extends State<SocialPostsList> {
  static const double _scrollThreshold = 400.0;

  Timer? _debounce;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.doesNextPageExist ? widget.posts.length + 1 : widget.posts.length,
      controller: _scrollController,
      itemBuilder: (BuildContext context, int index) {
        if (index >= widget.posts.length) {
          return const Center(child: CircularProgressIndicator());
        } else {
          final usersWhoLikedPost = widget.likedUserIds.firstWhere((element) => element.postId == widget.posts[index].postId);
          return _newsFeedListItem(widget.posts[index], widget.userIdProfileMap, usersWhoLikedPost);
        }
      },
    );
  }

  Widget _newsFeedListItem(
      SocialPost post,
      Map<String, PublicUserProfile> userIdProfileMap,
      PostsWithLikedUserIds likedUserIds
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
                  _getLikesAndComments(post, likedUserIds),
                  _getPostActionButtons(post, likedUserIds),
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
                    widget.buttonInteractionCallback(post, likedUserIds);
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
                    Navigator.pushAndRemoveUntil(
                        context,
                        SelectedPostView.route(
                            currentUserProfile: widget.currentUserProfile,
                            currentPostId: post.postId,
                            currentPost: post,
                            currentPostComments: widget.postIdCommentsMap[post.postId],
                            likedUsersForCurrentPost: widget.likedUserIds.firstWhere((element) => element.postId == post.postId),
                            userIdProfileMap: widget.userIdProfileMap
                        ), (route) => true
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


  void _onScroll() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if(_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        if (maxScroll - currentScroll <= _scrollThreshold) {
          widget.fetchMoreResultsCallback();
        }
      }
    });
  }

}