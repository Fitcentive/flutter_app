import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/user_profile.dart';
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
  final UserProfile userProfile;

  UserProfileView({required this.userProfile});

  static Route route(UserProfile userProfile) {
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
      appBar: AppBar(title: Text("View Profile")),
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
          children: [
            _userFirstAndLastName(),
            const Padding(padding: EdgeInsets.all(15)),
            _userAvatar(),
            const Padding(padding: EdgeInsets.all(10)),
            _userUsername(state.username),
            const Padding(padding: EdgeInsets.all(10)),
            _messageUserButton(),
            _followUserButton(state)
          ],
        ),
      ),
    );
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

  Widget _followUserButton(RequiredDataResolved state) {
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.message),
          style: ButtonStyle(
            backgroundColor: state.hasCurrentUserAlreadyRequestedToFollowUser
                ? MaterialStateProperty.all<Color>(Colors.grey)
                : MaterialStateProperty.all<Color>(Colors.teal),
          ),
          onPressed: () {
            // yet to do
            final currentAuthState = _authenticationBloc.state;
            final currentUserProfileState = _userProfileBloc.state;
            if (currentAuthState is AuthSuccessUserUpdateState &&
                currentUserProfileState is RequiredDataResolved &&
                !state.hasCurrentUserAlreadyRequestedToFollowUser
            ) {
              _userProfileBloc.add(RequestToFollowUser(
                targetUserId: widget.userProfile.userId,
                currentUser: currentAuthState.authenticatedUser,
                resolvedUsername: currentUserProfileState.username,
                hasCurrentUserAlreadyRequestedToFollowUser: true,
              ));
            }
          },
          label: Text(
              state.hasCurrentUserAlreadyRequestedToFollowUser ? "Requested to follow already" : 'Request to follow',
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
        ));
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
            image: _getUserProfileImage(widget.userProfile.photoUrl),
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

  DecorationImage? _getUserProfileImage(String? photoUrl) {
    if (photoUrl != null) {
      return DecorationImage(
          image: NetworkImage("${ImageUtils.imageBaseUrl}/$photoUrl?transform=200x200"), fit: BoxFit.fitHeight);
    } else {
      return null;
    }
  }
}
