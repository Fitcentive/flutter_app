import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/search/bloc/search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
import 'package:flutter_app/src/views/search/views/activity_search_view.dart';
import 'package:flutter_app/src/views/search/views/user_search_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const SearchView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<SearchBloc>(
          create: (context) => SearchBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: SearchView(currentUserProfile: currentUserProfile),
  );

  @override
  State createState() {
    return SearchViewState();
  }
}

class SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {

  late final SearchBloc _searchBloc;

  late final TabController _tabController;

  static const int MAX_TABS = 2;
  static const int USER_SEARCH_PAGE = 0;
  static const int ACTIVITY_SEARCH_PAGE = 1;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: MAX_TABS);
    _searchBloc = BlocProvider.of<SearchBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
      return DefaultTabController(
          length: MAX_TABS,
          child: Scaffold(
            appBar: AppBar(
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
                const ActivitySearchView(),
              ],
            ),
          )
      );
    });
  }
}