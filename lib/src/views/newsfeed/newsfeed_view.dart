import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
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
import 'package:flutter_app/src/views/shared_components/social_posts_list.dart';
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
  static const double _scrollThreshold = 400.0;

  late final NewsFeedBloc _newsFeedBloc;
  late final AuthenticationBloc _authenticationBloc;

  final TextEditingController _textController = TextEditingController();

  final _scrollController = ScrollController();
  bool isRequestingMoreData = false;

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
      _newsFeedBloc.add(
          NewsFeedFetchRequested(
              user: currentAuthState.authenticatedUser,
              createdBefore: DateTime.now().millisecondsSinceEpoch,
              limit: ConstantUtils.DEFAULT_NEWSFEED_LIMIT
          )
      );
    }

    _scrollController.addListener(_onScroll);
  }

  Future<void> _pullRefresh() async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _newsFeedBloc.add(
          NewsFeedReFetchRequested(
              user: currentAuthState.authenticatedUser,
              createdBefore: DateTime.now().millisecondsSinceEpoch,
              limit: ConstantUtils.DEFAULT_NEWSFEED_LIMIT
          )
      );
    }
  }

  Future<void> _fetchMoreResults() async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _newsFeedBloc.add(
          NewsFeedFetchRequested(
              user: currentAuthState.authenticatedUser,
              createdBefore: postsState.last.createdAt.add(DateTime.now().timeZoneOffset).millisecondsSinceEpoch,
              limit: ConstantUtils.DEFAULT_NEWSFEED_LIMIT
          )
      );
    }
  }


  Future<void> _likeOrUnlikePost(SocialPost post,  PostsWithLikedUserIds likedUserIds) async {
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  _newsFeedList(NewsFeedDataReady state) {
    return SocialPostsList(
        currentUserProfile: widget.currentUserProfile,
        posts: postsState,
        userIdProfileMap: state.userIdProfileMap,
        likedUserIds: likedUsersForPosts,
        doesNextPageExist: state.doesNextPageExist,
        postIdCommentsMap: state.postIdCommentsMap,
        fetchMoreResultsCallback: _fetchMoreResults,
        refreshCallback: _pullRefresh,
        buttonInteractionCallback: _likeOrUnlikePost
    );
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isRequestingMoreData) {
        isRequestingMoreData = true;
        _fetchMoreResults();
      }
    }
  }

  _newsfeedListView(NewsFeedState state) {
    if (state is NewsFeedDataReady) {
      isRequestingMoreData = false;
      if (state.posts.isNotEmpty) {
        postsState = state.posts;
        likedUsersForPosts = state.postsWithLikedUserIds;
        return RefreshIndicator(
          onRefresh: () async {
            _pullRefresh();
          },
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _addNewPostView(),
                  _separation(),
                  _newsFeedList(state)
                ],
              ),
            ),
          ),
        );
      }
      else {
        return RefreshIndicator(
          onRefresh: () async {
            _pullRefresh();
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
