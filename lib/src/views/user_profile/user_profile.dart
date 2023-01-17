import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/social_posts_list.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_bloc.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfileView extends StatefulWidget {
  static const String routeName = "user/profile";

  final PublicUserProfile userProfile;
  final PublicUserProfile currentUserProfile;

  const UserProfileView({Key? key, required this.currentUserProfile, required this.userProfile}) : super(key: key);

  static Route route(PublicUserProfile userProfile, PublicUserProfile currentUserProfile) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider<UserProfileBloc>(
                    create: (context) => UserProfileBloc(
                          userRepository: RepositoryProvider.of<UserRepository>(context),
                          chatRepository: RepositoryProvider.of<ChatRepository>(context),
                          socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
                          flutterSecureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                        )),
              ],
              child: UserProfileView(userProfile: userProfile, currentUserProfile: currentUserProfile),
            ));
  }

  @override
  State createState() {
    return UserProfileViewState();
  }
}

class UserProfileViewState extends State<UserProfileView> {
  static const double _scrollThreshold = 400.0;

  final _scrollController = ScrollController();
  bool isRequestingMoreData = false;

  late final UserProfileBloc _userProfileBloc;
  late final AuthenticationBloc _authenticationBloc;

  List<SocialPost>? postsState = List.empty();
  List<PostsWithLikedUserIds>? likedUsersForPosts = List.empty();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _userProfileBloc = BlocProvider.of<UserProfileBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _userProfileBloc.add(
          FetchRequiredData(
              userId: widget.userProfile.userId,
              currentUser: currentAuthState.authenticatedUser,
              createdBefore: DateTime.now().millisecondsSinceEpoch,
              limit: ConstantUtils.DEFAULT_NEWSFEED_LIMIT,
          )
      );
    }

    _scrollController.addListener(_onScroll);
  }

  _openUserChatView(String roomId, PublicUserProfile otherUserProfile) {
    Navigator.pushAndRemoveUntil(
        context,
        UserChatView.route(
            currentRoomId: roomId,
            currentUserProfile: widget.currentUserProfile,
            otherUserProfile: otherUserProfile
        ),
            (route) => true
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "View Profile",
          style: TextStyle(color: Colors.teal),
        ),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: BlocListener<UserProfileBloc, UserProfileState>(
        listener: (context, state) {
          if (state is GoToUserChatView) {
            _openUserChatView(state.roomId, widget.userProfile);
          }
          else if (state is TargetUserChatNotEnabled) {
            SnackbarUtils.showSnackBar(context, "This user has not enabled chat yet!");
          }
        },
        child: BlocBuilder<UserProfileBloc, UserProfileState>(builder: (context, state) {
          if (state is RequiredDataResolved) {
            isRequestingMoreData = false;
            return _buildUserProfilePage(state);
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
        }),
      ),
    );
  }

  Widget _buildUserProfilePage(RequiredDataResolved state) {
    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              _userFirstAndLastName(),
              const Padding(padding: EdgeInsets.all(15)),
              _userAvatar(),
              const Padding(padding: EdgeInsets.all(10)),
              _userUsername(widget.userProfile.username),
              const Padding(padding: EdgeInsets.all(10)),
              _messageUserButtonOpt(state),
              _friendUserButtonOpt(state),
              _acceptFriendRequestButtonOpt(state),
              _showUserPostsIfRequired(state)
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _pullRefresh() async {
    final state = _userProfileBloc.state;
    if (state is RequiredDataResolved) {
      _userProfileBloc.add(ReFetchUserPostsData(
        userId: widget.userProfile.userId,
        currentUser: state.currentUser,
        userFollowStatus: state.userFollowStatus,
        createdBefore: DateTime.now().millisecondsSinceEpoch,
        limit: ConstantUtils.DEFAULT_NEWSFEED_LIMIT,
      ));
    }
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


  Widget _showUserPostsIfRequired(RequiredDataResolved state) {
    if (state.userPosts == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Friend a user to view their posts")),
      );
    } else if (state.userPosts?.isEmpty ?? true) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Awfully quiet here....")),
      );
    } else {
      postsState = state.userPosts;
      likedUsersForPosts = state.usersWhoLikedPosts;
      return _newsfeedListView(state);
    }
  }

  Future<void> _likeOrUnlikePost(SocialPost post,  PostsWithLikedUserIds likedUserIds) async {
    List<String> newLikedUserIdsForCurrentPost = likedUserIds.userIds;
    final hasUserAlreadyLikedPost = newLikedUserIdsForCurrentPost.contains(widget.userProfile.userId);

    final currentAuthState = _authenticationBloc.state;
    final currentUserProfileState = _userProfileBloc.state;

    if (currentAuthState is AuthSuccessUserUpdateState
        && currentUserProfileState is RequiredDataResolved) {
      if (hasUserAlreadyLikedPost) {
        _userProfileBloc.add(
            UnlikePostForUser(
              currentUser: currentAuthState.authenticatedUser,
              postId: post.postId,
            ));
      }
      else {
        _userProfileBloc.add(
            LikePostForUser(
              currentUser: currentAuthState.authenticatedUser,
              postId: post.postId,
            ));
      }

    }

    setState(() {
      if (hasUserAlreadyLikedPost) {
        newLikedUserIdsForCurrentPost.remove(widget.userProfile.userId);
      }
      else {
        newLikedUserIdsForCurrentPost.add(widget.userProfile.userId);
      }
      likedUsersForPosts = likedUsersForPosts!.map((e) {
        if (e.postId == post.postId) {
          return PostsWithLikedUserIds(e.postId, newLikedUserIdsForCurrentPost);
        } else {
          return e;
        }
      }).toList();
    });
  }

  Future<void> _fetchMoreResults() async {
    final currentAuthState = _authenticationBloc.state;
    final currentState = _userProfileBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && currentState is RequiredDataResolved) {
      _userProfileBloc.add(FetchUserPostsData(
        userId: widget.userProfile.userId,
        currentUser: currentAuthState.authenticatedUser,
        userFollowStatus: currentState.userFollowStatus,
        createdBefore: postsState?.last.createdAt.add(DateTime.now().timeZoneOffset).millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        limit: ConstantUtils.DEFAULT_NEWSFEED_LIMIT,
      ));
    }
  }

  _newsfeedListView(RequiredDataResolved state) {
    if (postsState?.isNotEmpty ?? false) {
      return SocialPostsList(
          currentUserProfile: widget.currentUserProfile,
          posts: postsState!,
          userIdProfileMap: {
            widget.currentUserProfile.userId: widget.currentUserProfile,
            widget.userProfile.userId: widget.userProfile,
            ...state.userIdProfileMap!,
          },
          postIdCommentsMap: state.postIdCommentsMap!,
          likedUserIds: likedUsersForPosts!,
          doesNextPageExist: state.doesNextPageExist,
          fetchMoreResultsCallback: _fetchMoreResults,
          refreshCallback: _pullRefresh,
          buttonInteractionCallback: _likeOrUnlikePost
      );
    } else {
      return const Center(child: Text("Awfully quiet here...."));
    }
  }


  Widget? _messageUserButtonOpt(RequiredDataResolved state) {
    if (state.currentUser.user.id == state.userFollowStatus.otherUserId) {
      return null;
    }
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.message),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
          ),
          onPressed: () async {
            _userProfileBloc.add(GetChatRoom(targetUserId: widget.userProfile.userId));
          },
          label: const Text('Message user',
              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
        ),
        WidgetUtils.spacer(5)
      ],
    );
  }

  _getBackgroundColours(RequiredDataResolved state) {
    if (state.userFollowStatus.hasCurrentUserRequestedToFriendOtherUser) {
      return MaterialStateProperty.all<Color>(Colors.grey);
    } else {
      return MaterialStateProperty.all<Color>(Colors.teal);
    }
  }

  _getIcon(RequiredDataResolved state) {
    if (state.userFollowStatus.hasCurrentUserRequestedToFriendOtherUser) {
      return Icons.pending;
    } else {
      if (state.userFollowStatus.isCurrentUserFriendsWithOtherUser) {
        return Icons.remove;
      } else {
        return Icons.add;
      }
    }
  }

  _getText(RequiredDataResolved state) {
    if (state.userFollowStatus.hasCurrentUserRequestedToFriendOtherUser) {
      return "Friend request already sent!";
    } else {
      if (state.userFollowStatus.isCurrentUserFriendsWithOtherUser) {
        return "Unfriend";
      } else {
        return "Add as friend";
      }
    }
  }

  _friendUserButtonOnPressed() {
    final currentAuthState = _authenticationBloc.state;
    final currentUserProfileState = _userProfileBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && currentUserProfileState is RequiredDataResolved) {
      if (currentUserProfileState.userFollowStatus.isCurrentUserFriendsWithOtherUser) {
        _userProfileBloc.add(UnfriendUser(
            targetUserId: widget.userProfile.userId,
            currentUser: currentAuthState.authenticatedUser,
            userFollowStatus: currentUserProfileState.userFollowStatus,
            userPosts: currentUserProfileState.userPosts,
            usersWhoLikedPosts: currentUserProfileState.usersWhoLikedPosts,
        ));
      } else if (!currentUserProfileState.userFollowStatus.hasCurrentUserRequestedToFriendOtherUser) {
        _userProfileBloc.add(RequestToFriendUser(
            targetUserId: widget.userProfile.userId,
            currentUser: currentAuthState.authenticatedUser,
            userFollowStatus: currentUserProfileState.userFollowStatus,
            userPosts: currentUserProfileState.userPosts,
          usersWhoLikedPosts: currentUserProfileState.usersWhoLikedPosts,
        ));
      }
    }
  }


  Widget? _friendUserButtonOpt(RequiredDataResolved state) {
    if (state.currentUser.user.id == state.userFollowStatus.otherUserId) {
      return null;
    }
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(_getIcon(state)),
          style: ButtonStyle(backgroundColor: _getBackgroundColours(state)),
          onPressed: () {
            _friendUserButtonOnPressed();
          },
          label: Text(_getText(state),
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
        ),
        WidgetUtils.spacer(5),
      ],
    );
  }

  Widget? _acceptFriendRequestButtonOpt(RequiredDataResolved state) {
    if (!state.userFollowStatus.isCurrentUserFriendsWithOtherUser &&
        !state.userFollowStatus.hasOtherUserRequestedToFriendCurrentUser) {
      return null;
    } else if (state.userFollowStatus.hasOtherUserRequestedToFriendCurrentUser) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              children: [
                Text("${widget.userProfile.firstName} ${widget.userProfile.lastName} has sent you a friend request",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.teal)),
                          onPressed: () {
                            _applyUserFriendRequestDecision(true);
                          },
                          label: const Text("Approve",
                              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
                        )),
                    WidgetUtils.spacer(5),
                    Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent)),
                          onPressed: () {
                            _applyUserFriendRequestDecision(false);
                          },
                          label: const Text("Deny",
                              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
                        )),
                  ],
                ),
                WidgetUtils.spacer(5)
              ],
            ),
          ),
        ],
      );
    }
    return null;
  }

  _applyUserFriendRequestDecision(bool isFollowRequestApproved) {
    final currentAuthState = _authenticationBloc.state;
    final currentUserProfileState = _userProfileBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && currentUserProfileState is RequiredDataResolved) {
      _userProfileBloc.add(ApplyUserDecisionToFriendRequest(
          targetUserId: widget.userProfile.userId,
          currentUser: currentAuthState.authenticatedUser,
          userFollowStatus: currentUserProfileState.userFollowStatus,
          isFollowRequestApproved: isFollowRequestApproved,
          userPosts: currentUserProfileState.userPosts,
          usersWhoLikedPosts: currentUserProfileState.usersWhoLikedPosts,
      ));
    }
  }

  Widget _userUsername(String? username) {
    const style = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
    if (username != null) {
      return Text("@$username", style: style);
    }
    return const Text("", style: style);
  }

  Widget _userAvatar() {
    return CircleAvatar(
      radius: 100,
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(widget.userProfile, 200, 200),
          ),
        ),
      ),
    );
  }

  Widget _userFirstAndLastName() {
    return Center(
      child: Text(
        "${widget.userProfile.firstName} ${widget.userProfile.lastName}",
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
