import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/search/bloc/search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/search_event.dart';
import 'package:flutter_app/src/views/search/bloc/search_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class UserSearchView extends StatefulWidget {
  const UserSearchView({Key? key});

  @override
  State createState() {
    return UserSearchViewState();
  }
}

class UserSearchViewState extends State<UserSearchView> with AutomaticKeepAliveClientMixin {
  @override
  bool wantKeepAlive = true;

  late final SearchBloc _searchBloc;
  late final UserRepository _userRepository;
  late final FlutterSecureStorage _flutterSecureStorage;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();
  final _scrollController = ScrollController();

  bool shouldShow = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchBloc = BlocProvider.of<SearchBloc>(context);
    _userRepository = RepositoryProvider.of<UserRepository>(context);
    _flutterSecureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[_userSearchBar(), _userSearchBody()],
    );
  }

  Widget _userSearchBar() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchQueryModified) {
          _searchTextController.text = state.query;
          _searchTextController.selection = TextSelection.collapsed(offset: state.query.length);
        }
        return Padding(
            padding: const EdgeInsets.all(10.0),
            child: TypeAheadField<PublicUserProfile>(
              suggestionsBoxController: _suggestionsController,
              debounceDuration: const Duration(milliseconds: 300),
              textFieldConfiguration: TextFieldConfiguration(
                  onSubmitted: (value) {
                    _searchTextController.text = value.toString();
                    startFreshSearch(_searchTextController.value.text);
                  },
                  autocorrect: false,
                  onTap: () => _suggestionsController.toggle(),
                  onChanged: (text) {
                    shouldShow = true;
                  },
                  autofocus: true,
                  controller: _searchTextController,
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Search by name/username",
                      suffixIcon: IconButton(
                        onPressed: () {
                          _suggestionsController.close();
                          shouldShow = false;

                          final s = _searchBloc.state;
                          print("Adding to reset bloc");
                          print(s);
                          _searchBloc.add(const SearchQueryReset());
                        },
                        icon: const Icon(Icons.close),
                      ))),
              suggestionsCallback: (pattern) async {
                print("changing here and adding to query chnaged");
                _searchBloc.add(SearchQueryChanged(query: pattern));
                if (shouldShow) {
                  const limit = 5;
                  final accessToken =
                      await _flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
                  return await _userRepository.searchForUsers(pattern, limit, accessToken!);
                } else {
                  return List.empty();
                }
              },
              itemBuilder: (context, suggestion) {
                final s = suggestion;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: _getUserProfileImage(suggestion),
                      ),
                    ),
                  ),
                  title: Text("${s.firstName ?? ""} ${s.lastName ?? ""}"),
                  subtitle: Text(suggestion.username ?? ""),
                );
              },
              onSuggestionSelected: (suggestion) {
                _searchTextController.text = "${suggestion.firstName} ${suggestion.lastName}";
                startFreshSearch(_searchTextController.value.text);
              },
              hideOnEmpty: true,
            ));
      },
    );
  }

  Widget _userSearchBody() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (BuildContext context, SearchState state) {
        if (state is SearchStateInitial || state is SearchQueryModified) {
          return Expanded(
              child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.transparent)),
              child: const Center(child: Text('Search for user by name/username')),
            ),
          ));
        }
        if (state is SearchResultsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SearchResultsError) {
          return Expanded(child: Center(child: Text(state.error)));
        }
        if (state is SearchResultsLoaded) {
          return state.userData.isEmpty
              ? const Expanded(child: Center(child: Text('No Results')))
              : Expanded(child: _displayResults(state));
        } else {
          return const Center(child: Text("Error: Something went wrong"));
        }
      },
    );
  }

  Widget _displayResults(SearchResultsLoaded state) {
    return Column(
      children: [
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text(state.userData.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(child: _searchResults(state.userData))
      ],
    );
  }

  Widget _searchResults(List<PublicUserProfile> items) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        if (index >= items.length) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return _userSearchResultItem(items[index]);
        }
      },
    );
  }

  Widget _userSearchResultItem(PublicUserProfile userProfile) {
    return ListTile(
      title: Text("${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Text(""),
      subtitle: const Text("username"),
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: _getUserProfileImage(userProfile),
          ),
        ),
      ),
      onTap: () {
        Navigator.pushAndRemoveUntil(context, UserProfileView.route(userProfile), (route) => true);
      },
    );
  }

  DecorationImage? _getUserProfileImage(PublicUserProfile? profile) {
    final photoUrlOpt = profile?.photoUrl;
    if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("${ImageUtils.imageBaseUrl}/$photoUrlOpt?transform=100x100"), fit: BoxFit.fitHeight);
    } else {
      return null;
    }
  }

  void startFreshSearch(String searchQuery) {
    _searchBloc.add(SearchQuerySubmitted(query: searchQuery));
  }
}
