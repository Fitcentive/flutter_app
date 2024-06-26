import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/friends/bloc/friends_bloc.dart';
import 'package:flutter_app/src/views/friends/bloc/friends_event.dart';
import 'package:flutter_app/src/views/friends/bloc/friends_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class FriendsView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const FriendsView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<FollowersBloc>(
          create: (context) => FollowersBloc(
            socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: FriendsView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return FriendsViewState();
  }

}

class FriendsViewState extends State<FriendsView> {

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
          FetchFriendsRequested(
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
        if (state is FriendsDataLoaded) {
          return state.userProfiles.isEmpty ?
              const Center(child: Text('No friends here... get started by adding one!'))
              : _generateUserResultsList(state);
        } else {
          if (DeviceUtils.isAppRunningOnMobileBrowser()) {
            return WidgetUtils.progressIndicator();
          }
          else {
            return _skeletonLoadingView();
          }
        }
      }),
    );
  }

  _skeletonLoadingView() {
    return SingleChildScrollView(
      child: SkeletonLoader(
        builder: ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            return _userSearchResultItemStub();
          },
        ),
      ),
    );
  }

  _userSearchResultItemStub() {
    return ListTile(
      title: Container(
        width: ScreenUtils.getScreenWidth(context),
        height: 10,
        color: Colors.white,
      ),
      subtitle:  Container(
        width: 25,
        height: 10,
        color: Colors.white,
      ),
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 500, 500),
          ),
        ),
      ),
    );
  }

  _generateUserResultsList(FriendsDataLoaded state) {
    return RefreshIndicator(
        onRefresh: _pullRefresh,
        child: UserResultsList(
            userProfiles: state.userProfiles,
            currentUserProfile: widget.currentUserProfile,
            fetchMoreResultsCallback: _fetchMoreResultsCallback,
            doesNextPageExist: state.doesNextPageExist,
            swipeToDismissUserCallback: null,
            listHeadingText: "Total Friends",
        ),
    );
  }

  _fetchMoreResultsCallback() {
    final currentAuthState = _authenticationBloc.state;
    final currentFollowingState = _followersBloc.state;

    if (currentAuthState is AuthSuccessUserUpdateState &&
        currentFollowingState is FriendsDataLoaded) {
      _followersBloc.add(const TrackViewFriendsEvent());
      _followersBloc.add(
          FetchFriendsRequested(
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
          ReFetchFriendsRequested(
              userId: currentAuthState.authenticatedUser.user.id,
              limit: ConstantUtils.DEFAULT_LIMIT,
              offset: ConstantUtils.DEFAULT_OFFSET
          )
      );
    }
  }

}