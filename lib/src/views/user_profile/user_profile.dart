import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_bloc.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfileView extends StatefulWidget {
  final PublicUserProfile userProfile;

  UserProfileView({required this.userProfile});

  static Route route(PublicUserProfile userProfile) {
    return MaterialPageRoute<void>(
        builder: (_) =>
            MultiBlocProvider(
              providers: [
                BlocProvider<UserProfileBloc>(
                    create: (context) =>
                        UserProfileBloc(
                          userRepository: RepositoryProvider.of<UserRepository>(context),
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
      appBar: AppBar(title: const Text("View Profile", style: TextStyle(color: Colors.teal),)),
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
          children: skipNulls([
            _userFirstAndLastName(),
            const Padding(padding: EdgeInsets.all(15)),
            _userAvatar(),
            const Padding(padding: EdgeInsets.all(10)),
            _userUsername(widget.userProfile.username),
            const Padding(padding: EdgeInsets.all(10)),
            _messageUserButton(),
            _followUserButton(state),
            _removeUserFromFollowersButtonOpt(state),
          ]),
        ),
      ),
    );
  }


  List<T> skipNulls<T>(List<T?> items) {
    return items.whereType<T>().toList();
  }

  Future<void> _pullRefresh() async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _userProfileBloc.add(
          FetchRequiredData(userId: widget.userProfile.userId, currentUser: currentAuthState.authenticatedUser));
    }
  }

  Widget _messageUserButton() {
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
      }
      else {
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
      }
      else {
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
            userFollowStatus: currentUserProfileState.userFollowStatus
        ));
      } else if (!currentUserProfileState.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser) {
        _userProfileBloc.add(RequestToFollowUser(
            targetUserId: widget.userProfile.userId,
            currentUser: currentAuthState.authenticatedUser,
            userFollowStatus: currentUserProfileState.userFollowStatus
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
          userFollowStatus: currentUserProfileState.userFollowStatus
      ));
    }
  }

  Widget _followUserButton(RequiredDataResolved state) {
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ElevatedButton.icon(
          icon: Icon(_getIcon(state)),
          style: ButtonStyle(
            backgroundColor: _getBackgroundColours(state)
          ),
          onPressed: () {
            // yet to do
            _followUserButtonOnPressed();
          },
          label: Text(
              _getText(state),
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
        ));
  }

  Widget? _removeUserFromFollowersButtonOpt(RequiredDataResolved state) {
    if (!state.userFollowStatus.isOtherUserFollowingCurrentUser && !state.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser) {
      return null;
    }
    else if (state.userFollowStatus.isOtherUserFollowingCurrentUser) {
      return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.remove),
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.teal)),
            onPressed: () {
              // yet to do
              _removeUserFromFollowersButtonPressed();
            },
            label: const Text(
                "Remove user from followers",
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
          ));
    }
    else if (state.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          children: [
            Text("${widget.userProfile.firstName} ${widget.userProfile.lastName} has requested to follow you",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)
            ),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.teal)),
                  onPressed: () {
                    _applyUserFollowRequestDecision(true);
                  },
                  label: const Text("Approve",
                      style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
                )),

                Expanded(child: ElevatedButton.icon(
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
