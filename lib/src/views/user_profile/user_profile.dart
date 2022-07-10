import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_bloc.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfileView extends StatefulWidget {
  final PublicUserProfile userProfile;

  const UserProfileView({Key? key, required this.userProfile}) : super(key: key);

  static Route route(PublicUserProfile userProfile) {
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
              child: UserProfileView(userProfile: userProfile),
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
          return _buildUserProfilePage(state);
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
      return _newsfeedListView(state.userPosts!);
    }
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
            return _newsFeedListItem(userPosts[index], widget.userProfile);
          }
        },
      );
    } else {
      return const Center(child: Text("Awfully quiet here...."));
    }
  }

  Widget _newsFeedListItem(SocialPost post, PublicUserProfile userProfile) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              Row(
                children: [
                  CircleAvatar(
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
                  WidgetUtils.spacer(20),
                  Text(
                    StringUtils.getUserNameFromUserId(post.userId, userProfile),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              ),
              WidgetUtils.spacer(10),
              Row(
                children: [
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
                    child: Text(post.text),
                  ))
                ],
              ),
              WidgetUtils.spacer(5),
              WidgetUtils.generatePostImageIfExists(post.photoUrl),
              WidgetUtils.spacer(5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text("${post.numberOfLikes} people like this"),
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
              ),
              Row(
                children: [
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(2.5),
                    child: ElevatedButton(
                        onPressed: () {},
                        child: const Text(
                          "Like",
                          style: TextStyle(fontSize: 12),
                        )),
                  )),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(2.5),
                    child: ElevatedButton(
                        onPressed: () {},
                        child: const Text(
                          "Comment",
                          style: TextStyle(fontSize: 12),
                        )),
                  )),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(2.5),
                    child: ElevatedButton(
                        onPressed: () {},
                        child: const Text(
                          "Share",
                          style: TextStyle(fontSize: 12),
                        )),
                  )),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget? _messageUserButton(RequiredDataResolved state) {
    if (state.currentUser.user.id == state.userFollowStatus.currentUserId) {
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
            userPosts: currentUserProfileState.userPosts));
      } else if (!currentUserProfileState.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser) {
        _userProfileBloc.add(RequestToFollowUser(
            targetUserId: widget.userProfile.userId,
            currentUser: currentAuthState.authenticatedUser,
            userFollowStatus: currentUserProfileState.userFollowStatus,
            userPosts: currentUserProfileState.userPosts));
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
          userPosts: currentUserProfileState.userPosts));
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
          userPosts: currentUserProfileState.userPosts));
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
