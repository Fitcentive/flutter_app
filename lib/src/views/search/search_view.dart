import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/search/bloc/activity_search/activity_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/search_event.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/user_search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/user_search_state.dart';
import 'package:flutter_app/src/views/search/views/activity_search_view.dart';
import 'package:flutter_app/src/views/search/views/user_search_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const SearchView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<UserSearchBloc>(
          create: (context) => UserSearchBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
      BlocProvider<ActivitySearchBloc>(
          create: (context) => ActivitySearchBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
      BlocProvider<SearchBloc>(
          create: (context) => SearchBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: SearchView(currentUserProfile: currentUserProfile),
  );

  @override
  State createState() {
    return SearchViewState();
  }
}

class SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {

  late final TabController _tabController;

  static const int MAX_TABS = 2;
  static const int USER_SEARCH_PAGE = 0;
  static const int ACTIVITY_SEARCH_PAGE = 1;

  late SearchBloc searchBloc;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: MAX_TABS);

    searchBloc = BlocProvider.of<SearchBloc>(context);
    searchBloc.add(FetchFitnessUserProfile(currentUserId: widget.currentUserProfile.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is UserFitnessProfileFetched) {
            // If user does not have a fitness profile, only show user search
            // This is because user weight is needed to calculate calories
            if (state.fitnessUserProfile != null) {
              return DefaultTabController(
                  length: MAX_TABS,
                  child: Scaffold(
                    appBar: AppBar(
                      iconTheme: const IconThemeData(
                        color: Colors.teal,
                      ),
                      toolbarHeight: 75,
                      title: TabBar(
                        labelColor: Colors.teal,
                        controller: _tabController,
                        tabs: const [
                          Tab(icon: Icon(Icons.search, color: Colors.teal,), text: "User Search"),
                          Tab(icon: Icon(Icons.saved_search, color: Colors.teal,), text: "Activity Search"),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        UserSearchView(currentUserProfile: widget.currentUserProfile),
                        ActivitySearchView(
                          currentUserProfile: widget.currentUserProfile,
                          currentFitnessUserProfile: state.fitnessUserProfile!,
                        ),
                      ],
                    ),
                  )
              );
            }
            else {
              return DefaultTabController(
                  length: MAX_TABS - 1,
                  child: Scaffold(
                    appBar: AppBar(
                      iconTheme: const IconThemeData(
                        color: Colors.teal,
                      ),
                      toolbarHeight: 75,
                      title: TabBar(
                        labelColor: Colors.teal,
                        controller: _tabController,
                        tabs: const [
                          Tab(icon: Icon(Icons.search, color: Colors.teal,), text: "User Search"),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        UserSearchView(currentUserProfile: widget.currentUserProfile),
                      ],
                    ),
                  )
              );
            }
          }
          else {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            );
          }
    });
  }
}