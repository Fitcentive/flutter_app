import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_post/create_new_post_view.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_bloc.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_event.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/selected_post/selected_post_view.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NewsFeedView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const NewsFeedView({Key? key, required this.currentUserProfile}) : super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
        providers: [
          BlocProvider<NewsFeedBloc>(
              create: (context) => NewsFeedBloc(
                    socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  )),
        ],
        child: NewsFeedView(currentUserProfile: currentUserProfile),
      );

  @override
  State createState() {
    return NewsFeedViewState();
  }
}

class NewsFeedViewState extends State<NewsFeedView> {
  late final NewsFeedBloc _newsFeedBloc;
  late final AuthenticationBloc _authenticationBloc;

  final TextEditingController _textController = TextEditingController();

  List<SocialPost> postsState = List.empty();
  List<PostsWithLikedUserIds> likedUsersForPosts = List.empty();

  @override
  void initState() {
    super.initState();

    _newsFeedBloc = BlocProvider.of<NewsFeedBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    _textController.text = "Share something with your community";

    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _newsFeedBloc.add(NewsFeedFetchRequested(user: currentAuthState.authenticatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsFeedBloc, NewsFeedState>(
        builder: (context, state) {
          return Scaffold(
            body: _newsfeedListView(state),
          );
        });
  }

  _newsfeedListView(NewsFeedState state) {
    if (state is NewsFeedDataReady) {
      if (state.posts.isNotEmpty) {
        postsState = state.posts;
        likedUsersForPosts = state.postsWithLikedUserIds;
        return RefreshIndicator(
          onRefresh: () async {
            _newsFeedBloc.add(NewsFeedFetchRequested(user: state.user));
          },
          child: ListView.builder(
            itemCount: postsState.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Column(
                  children: [
                    _addNewPostView(),
                    _separation(),
                  ],
                );
              }
              if (index >= postsState.length + 1) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final usersWhoLikedPost = likedUsersForPosts
                    .firstWhere((element) => element.postId == postsState[index - 1].postId);
                return _newsFeedListItem(postsState[index - 1], state.userIdProfileMap, usersWhoLikedPost);
              }
            },
          ),
        );
      }
      else {
        return RefreshIndicator(
          onRefresh: () async {
            _newsFeedBloc.add(NewsFeedFetchRequested(user: state.user));
          },
          child: ListView(
            children: [
                Center(child: _addNewPostView()),
                _separation(),
                _showNoResults(),
            ],
          ),
        );
      }
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  _showNoResults() {
    return Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Text("Awfully quiet here...."),
        )
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
                    List<String> newLikedUserIdsForCurrentPost = likedUserIds.userIds;
                    final hasUserAlreadyLikedPost = newLikedUserIdsForCurrentPost.contains(widget.currentUserProfile.userId);

                    if (hasUserAlreadyLikedPost) {
                      _newsFeedBloc.add(UnlikePostForUser(userId: widget.currentUserProfile.userId, postId: post.postId));
                    } else {
                      _newsFeedBloc.add(LikePostForUser(userId: widget.currentUserProfile.userId, postId: post.postId));
                    }

                    setState(() {
                      if (hasUserAlreadyLikedPost) {
                        newLikedUserIdsForCurrentPost.remove(widget.currentUserProfile.userId);
                      }
                      else {
                        newLikedUserIdsForCurrentPost.add(widget.currentUserProfile.userId);
                      }
                      likedUsersForPosts = likedUsersForPosts.map((e) {
                        if (e.postId == post.postId) {
                          return PostsWithLikedUserIds(e.postId, newLikedUserIdsForCurrentPost);
                        } else {
                          return e;
                        }
                      }).toList();
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
                    Navigator.pushAndRemoveUntil(
                          context,
                          SelectedPostView.route(widget.currentUserProfile, post.postId),
                          (route) => true
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

  Widget _separation() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
              child: Container(
                height: 30,
                width: 30,
                color: Colors.teal,
              )
          )
        ],
      ),
    );
  }

  Widget _addNewPostView() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  UserProfileView.route(widget.currentUserProfile, widget.currentUserProfile),
                      (route) => true
              );
            },
            child: CircleAvatar(
              radius: 30,
              child: Container(
                padding: const EdgeInsets.all(5),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 100, 100),
                ),
              ),
            ),
          ),
          WidgetUtils.spacer(10),
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(context, CreateNewPostView.route(widget.currentUserProfile), (route) => true);
            },
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Container(
                    padding: const EdgeInsets.all(15),
                    child: const Center(
                      child: Text("Share something with your community"),
                    )
                )
            ),
          )
        ],
      ),
    );
  }
}
