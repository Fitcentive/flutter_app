import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/shared_components/liked_users/bloc/liked_users_bloc.dart';
import 'package:flutter_app/src/views/shared_components/liked_users/bloc/liked_users_event.dart';
import 'package:flutter_app/src/views/shared_components/liked_users/bloc/liked_users_state.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LikedUsersView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final List<String> likedUserIds;

  const LikedUsersView({Key? key, required this.currentUserProfile, required this.likedUserIds}) : super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile, List<String> likedUserIds) => MultiBlocProvider(
    providers: [
      BlocProvider<LikedUsersBloc>(
          create: (context) => LikedUsersBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: LikedUsersView(currentUserProfile: currentUserProfile, likedUserIds: likedUserIds),
  );

  @override
  State createState() {
    return LikedUsersViewState();
  }
}

class LikedUsersViewState extends State<LikedUsersView> {

  late final LikedUsersBloc _likedUsersBloc;

  @override
  void initState() {
    super.initState();
    _likedUsersBloc = BlocProvider.of<LikedUsersBloc>(context);
    _likedUsersBloc.add(FetchedLikedUserProfiles(userIds: widget.likedUserIds));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikedUsersBloc, LikedUsersState>(
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.teal,
                    width: 2.5
                ),
            ),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Liked users', style: TextStyle(color: Colors.teal)),
                automaticallyImplyLeading: false,
                iconTheme: const IconThemeData(
                  color: Colors.teal,
                ),
              ),
              body: _userResultsList(state),
            ),
          );
        });
  }

  _userResultsList(LikedUsersState state) {
    if (state is LikedUsersProfilesLoaded) {
      return UserResultsList(
        userProfiles: state.userProfiles,
        currentUserProfile: widget.currentUserProfile,
        fetchMoreResultsCallback: () {},
        doesNextPageExist: false,
        swipeToDismissUserCallback: null,
        listHeadingText: "Total Users",
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

}