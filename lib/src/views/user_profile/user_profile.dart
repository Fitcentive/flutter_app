import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/comments_list.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_bloc.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class UserProfileView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final PublicUserProfile currentUserProfile;

  const UserProfileView({Key? key, required this.currentUserProfile, required this.userProfile}) : super(key: key);

  static Route route(PublicUserProfile userProfile, PublicUserProfile currentUserProfile) {
    return MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider<UserProfileBloc>(
                    create: (context) => UserProfileBloc(
                          userRepository: RepositoryProvider.of<UserRepository>(context),
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
  late final UserProfileBloc _userProfileBloc;
  late final AuthenticationBloc _authenticationBloc;

  List<SocialPost>? postsState = List.empty();
  List<PostsWithLikedUserIds>? likedUsersForPosts = List.empty();

  final PanelController _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    _userProfileBloc = BlocProvider.of<UserProfileBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _userProfileBloc
          .add(FetchRequiredData(userId: widget.userProfile.userId, currentUser: currentAuthState.authenticatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        "View Profile",
        style: TextStyle(color: Colors.teal),
      )),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(builder: (context, state) {
        if (state is RequiredDataResolved) {
          return SlidingUpPanel(
            controller: _panelController,
            minHeight: 0,
            panel: _generateSlidingPanel(state),
            body: _buildUserProfilePage(state),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
      }),
    );
  }

  Widget _buildUserProfilePage(RequiredDataResolved state) {
    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: WidgetUtils.skipNulls([
            _userFirstAndLastName(),
            const Padding(padding: EdgeInsets.all(15)),
            _userAvatar(),
            const Padding(padding: EdgeInsets.all(10)),
            _userUsername(widget.userProfile.username),
            const Padding(padding: EdgeInsets.all(10)),
            _messageUserButton(state),
            _followUserButton(state),
            _removeUserFromFollowersButtonOpt(state),
            _showUserPostsIfRequired(state)
          ]),
        ),
      ),
    );
  }

  Future<void> _pullRefresh() async {
    final state = _userProfileBloc.state;
    if (state is RequiredDataResolved) {
      _userProfileBloc.add(FetchUserPostsData(
        userId: widget.userProfile.userId,
        currentUser: state.currentUser,
        userFollowStatus: state.userFollowStatus,
      ));
    }
  }

  Widget? _showUserPostsIfRequired(RequiredDataResolved state) {
    if (state.userPosts == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Follow user to view their posts")),
      );
    } else if (state.userPosts?.isEmpty ?? true) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Awfully quiet here....")),
      );
    } else {
      postsState = state.userPosts;
      likedUsersForPosts = state.usersWhoLikedPosts;
      return _newsfeedListView(state.userPosts!);
    }
  }

  _generateSlidingPanel(RequiredDataResolved state) {
    return CommentsListView.withBloc(
        key: Key(state.selectedPostId ?? "null"),
        postId: state.selectedPostId
    );
  }

  _newsfeedListView(List<SocialPost> userPosts) {
    if (userPosts.isNotEmpty) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: userPosts.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= userPosts.length) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final usersWhoLikedPost = likedUsersForPosts!
                .firstWhere((element) => element.postId == postsState![index].postId);
            return _newsFeedListItem(userPosts[index], usersWhoLikedPost);
          }
        },
      );
    } else {
      return const Center(child: Text("Awfully quiet here...."));
    }
  }

  _userHeader(PublicUserProfile? publicUser) {
    return Row(
      children: [
        CircleAvatar(
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
                  icon: likedUserIds.userIds.contains(widget.userProfile.userId) ?
                  const Icon(Icons.thumb_down) : const Icon(Icons.thumb_up),
                  onPressed: () {
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
                  },
                  label: Text(likedUserIds.userIds.contains(widget.userProfile.userId) ? "Unlike" : "Like",
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
                    _userProfileBloc.add(ViewCommentsForSelectedPost(postId: post.postId));
                    _panelController.animatePanelToPosition(1.0, duration: const Duration(milliseconds: 250));
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

  Widget _newsFeedListItem(SocialPost post, PostsWithLikedUserIds likedUserIds) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              _userHeader(widget.userProfile),
              WidgetUtils.spacer(10),
              _userPostText(post),
              WidgetUtils.spacer(5),
              WidgetUtils.generatePostImageIfExists(post.photoUrl),
              WidgetUtils.spacer(5),
              _getLikesAndComments(post, likedUserIds),
              _getPostActionButtons(post, likedUserIds),
            ]),
          ),
        ),
      ),
    );
  }

  Widget? _messageUserButton(RequiredDataResolved state) {
    print("Message user button run opt");
    if (state.currentUser.user.id == state.userFollowStatus.otherUserId) {
      print("Doing fuck all");
      return null;
    }
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.message),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
          ),
          onPressed: () {
            // yet to do
          },
          label: const Text('Message user',
              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
        ));
  }

  _getBackgroundColours(RequiredDataResolved state) {
    if (state.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser) {
      return MaterialStateProperty.all<Color>(Colors.grey);
    } else {
      return MaterialStateProperty.all<Color>(Colors.teal);
    }
  }

  _getIcon(RequiredDataResolved state) {
    if (state.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser) {
      return Icons.pending;
    } else {
      if (state.userFollowStatus.isCurrentUserFollowingOtherUser) {
        return Icons.remove;
      } else {
        return Icons.add;
      }
    }
  }

  _getText(RequiredDataResolved state) {
    if (state.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser) {
      return "Requested to follow already";
    } else {
      if (state.userFollowStatus.isCurrentUserFollowingOtherUser) {
        return "Unfollow";
      } else {
        return "Follow";
      }
    }
  }

  _followUserButtonOnPressed() {
    final currentAuthState = _authenticationBloc.state;
    final currentUserProfileState = _userProfileBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && currentUserProfileState is RequiredDataResolved) {
      if (currentUserProfileState.userFollowStatus.isCurrentUserFollowingOtherUser) {
        _userProfileBloc.add(UnfollowUser(
            targetUserId: widget.userProfile.userId,
            currentUser: currentAuthState.authenticatedUser,
            userFollowStatus: currentUserProfileState.userFollowStatus,
            userPosts: currentUserProfileState.userPosts,
            usersWhoLikedPosts: currentUserProfileState.usersWhoLikedPosts,
        ));
      } else if (!currentUserProfileState.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser) {
        _userProfileBloc.add(RequestToFollowUser(
            targetUserId: widget.userProfile.userId,
            currentUser: currentAuthState.authenticatedUser,
            userFollowStatus: currentUserProfileState.userFollowStatus,
            userPosts: currentUserProfileState.userPosts,
          usersWhoLikedPosts: currentUserProfileState.usersWhoLikedPosts,
        ));
      }
    }
  }

  _removeUserFromFollowersButtonPressed() {
    final currentAuthState = _authenticationBloc.state;
    final currentUserProfileState = _userProfileBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && currentUserProfileState is RequiredDataResolved) {
      _userProfileBloc.add(RemoveUserFromCurrentUserFollowers(
          targetUserId: widget.userProfile.userId,
          currentUser: currentAuthState.authenticatedUser,
          userFollowStatus: currentUserProfileState.userFollowStatus,
          userPosts: currentUserProfileState.userPosts,
          usersWhoLikedPosts: currentUserProfileState.usersWhoLikedPosts,
      ));
    }
  }

  Widget? _followUserButton(RequiredDataResolved state) {
    if (state.currentUser.user.id == state.userFollowStatus.otherUserId) {
      return null;
    }
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ElevatedButton.icon(
          icon: Icon(_getIcon(state)),
          style: ButtonStyle(backgroundColor: _getBackgroundColours(state)),
          onPressed: () {
            // yet to do
            _followUserButtonOnPressed();
          },
          label: Text(_getText(state),
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
        ));
  }

  Widget? _removeUserFromFollowersButtonOpt(RequiredDataResolved state) {
    if (!state.userFollowStatus.isOtherUserFollowingCurrentUser &&
        !state.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser) {
      return null;
    } else if (state.userFollowStatus.isOtherUserFollowingCurrentUser) {
      return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.remove),
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.teal)),
            onPressed: () {
              // yet to do
              _removeUserFromFollowersButtonPressed();
            },
            label: const Text("Remove user from followers",
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
          ));
    } else if (state.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          children: [
            Text("${widget.userProfile.firstName} ${widget.userProfile.lastName} has requested to follow you",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.teal)),
                  onPressed: () {
                    _applyUserFollowRequestDecision(true);
                  },
                  label: const Text("Approve",
                      style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
                )),
                Expanded(
                    child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent)),
                  onPressed: () {
                    _applyUserFollowRequestDecision(false);
                  },
                  label: const Text("Deny",
                      style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
                )),
              ],
            )
          ],
        ),
      );
    }
    return null;
  }

  _applyUserFollowRequestDecision(bool isFollowRequestApproved) {
    final currentAuthState = _authenticationBloc.state;
    final currentUserProfileState = _userProfileBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && currentUserProfileState is RequiredDataResolved) {
      _userProfileBloc.add(ApplyUserDecisionToFollowRequest(
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
