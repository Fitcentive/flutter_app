import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_bloc.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_event.dart';
import 'package:flutter_app/src/views/followers/bloc/followers_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FollowersView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const FollowersView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<FollowersBloc>(
          create: (context) => FollowersBloc(
            socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: FollowersView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return FollowersViewState();
  }

}

class FollowersViewState extends State<FollowersView> {

  late final FollowersBloc _followersBloc;
  late final AuthenticationBloc _authenticationBloc;

  @override
  void initState() {
    super.initState();

    _followersBloc = BlocProvider.of<FollowersBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      _followersBloc.add(
          FetchFollowersRequested(
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
      body: BlocBuilder<FollowersBloc, FollowersState>(builder: (context, state) {
        if (state is FollowersDataLoaded) {
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

  _generateUserResultsList(FollowersDataLoaded state) {
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
    final currentFollowingState = _followersBloc.state;

    if (currentAuthState is AuthSuccessUserUpdateState &&
        currentFollowingState is FollowersDataLoaded) {
      _followersBloc.add(
          FetchFollowersRequested(
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
      _followersBloc.add(
          ReFetchFollowersRequested(
              userId: currentAuthState.authenticatedUser.user.id,
              limit: ConstantUtils.DEFAULT_LIMIT,
              offset: ConstantUtils.DEFAULT_OFFSET
          )
      );
    }
  }

}