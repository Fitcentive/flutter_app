import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/views/search/bloc/search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
import 'package:flutter_app/src/views/search/views/user_search_result_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserSearchBody extends StatefulWidget {

  const UserSearchBody({Key? key}) : super(key: key);

  @override
  State createState() {
    return UserSearchBodyState();
  }
}

class UserSearchBodyState extends State<UserSearchBody> with AutomaticKeepAliveClientMixin {

  @override
  bool wantKeepAlive = true;

  static const double _scrollThreshold = 200.0;

  late final SearchBloc _searchBloc;
  final _scrollController = ScrollController();
  late final Timer _debounce;

  void _onScroll() {
    if (_debounce.isActive) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if(_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        // Todo - need to do pagination querying here
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchBloc = BlocProvider.of<SearchBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (BuildContext context, SearchState state) {
        if (state is SearchStateInitial) {
          return Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent)
                ),
                child: const Center(
                  child: Text(
                    'Search for user by name/username'
                  )
                ),
              ),
            )
          );
        }
        if (state is SearchResultsLoading) {
          return const Center(
              child: CircularProgressIndicator()
          );
        }
        if (state is SearchResultsError) {
          return Expanded(child: Center(child: Text(state.error)));
        }
        if (state is SearchResultsLoaded) {
          return state.userData.isEmpty
              ? const Expanded(child: Center(child: Text('No Results')))
              : Expanded(child: _displayResults(state));
        }
        else {
          return const Center(child: Text("Error: Something went wrong"));
        }
      },
    );
  }

  Widget _displayResults(SearchResultsLoaded state) {
    return Column(
      children: [
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.tealAccent)),
          trailing: Text(state.userData.length.toString(), style: const TextStyle(color: Colors.tealAccent)),
        ),
        Expanded(child: _searchResults(state.userData))
      ],
    );
  }

  Widget _searchResults(List<UserProfile> items) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        if (index >= items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        else {
          return UserSearchResultItem(userProfile: items[index]);
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}