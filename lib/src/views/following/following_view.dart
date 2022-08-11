import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/following/bloc/following_bloc.dart';
import 'package:flutter_app/src/views/following/bloc/following_event.dart';
import 'package:flutter_app/src/views/following/bloc/following_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowingUsersView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const FollowingUsersView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<FollowingBloc>(
          create: (context) => FollowingBloc(
            socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: FollowingUsersView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return FollowingUsersViewState();
  }

}

class FollowingUsersViewState extends State<FollowingUsersView> {

  late final FollowingBloc _followingBloc;
  late final AuthenticationBloc _authenticationBloc;

  @override
  void initState() {
    super.initState();

    _followingBloc = BlocProvider.of<FollowingBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      _followingBloc.add(
          FetchFollowingUsersRequested(
              userId: authState.authenticatedUser.user.id,
              limit: ConstantUtils.DEFAULT_LIMIT,
              offset: ConstantUtils.DEFAULT_OFFSET
          )
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FollowingBloc, FollowingState>(builder: (context, state) {
        if (state is FollowingUsersDataLoaded) {
          return state.userProfiles.isEmpty ? const Center(child: Text('No Results'))
              : _generateUserResultsList(state);
        } else {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
      }),
    );
  }

  _generateUserResultsList(FollowingUsersDataLoaded state) {
    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: UserResultsList(
          userProfiles: state.userProfiles,
          currentUserProfile: widget.currentUserProfile,
          fetchMoreResultsCallback: _fetchMoreResultsCallback,
          doesNextPageExist: state.doesNextPageExist,
      ),
    );
  }

  _fetchMoreResultsCallback() {
    final currentAuthState = _authenticationBloc.state;
    final currentFollowingState = _followingBloc.state;

    if (currentAuthState is AuthSuccessUserUpdateState &&
        currentFollowingState is FollowingUsersDataLoaded) {
      _followingBloc.add(
          FetchFollowingUsersRequested(
              userId: currentAuthState.authenticatedUser.user.id,
              limit: ConstantUtils.DEFAULT_LIMIT,
              offset: currentFollowingState.userProfiles.length
          )
      );
    }
  }

  Future<void> _pullRefresh() async {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _followingBloc.add(
          ReFetchFollowingUsersRequested(
              userId: currentAuthState.authenticatedUser.user.id,
              limit: ConstantUtils.DEFAULT_LIMIT,
              offset: ConstantUtils.DEFAULT_OFFSET
          )
      );
    }
  }

}