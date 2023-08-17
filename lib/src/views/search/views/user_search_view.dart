import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/user_search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/user_search_event.dart';
import 'package:flutter_app/src/views/search/bloc/user_search/user_search_state.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class UserSearchView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const UserSearchView({Key? key, required this.currentUserProfile}): super(key: key);

  @override
  State createState() {
    return UserSearchViewState();
  }
}

class UserSearchViewState extends State<UserSearchView> with AutomaticKeepAliveClientMixin {
  @override
  bool wantKeepAlive = true;

  late final UserSearchBloc _searchBloc;
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
    _searchBloc = BlocProvider.of<UserSearchBloc>(context);
    _userRepository = RepositoryProvider.of<UserRepository>(context);
    _flutterSecureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);

    _searchBloc.add(
        FetchUserFriends(
            currentUserId: widget.currentUserProfile.userId,
            limit: ConstantUtils.DEFAULT_LIMIT,
            offset: ConstantUtils.DEFAULT_OFFSET
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _userSearchBar(),
        _userSearchBody()
      ],
    );
  }

  Widget _userSearchBar() {
    return BlocBuilder<UserSearchBloc, UserSearchState>(
      builder: (context, state) {
        if (state is UserSearchQueryModified) {
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
                    if (value.trim().isNotEmpty) {
                      startFreshSearch(value.trim());
                    }
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
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _suggestionsController.close();
                          shouldShow = false;
                          _searchBloc.add(SearchQueryReset(currentUserId: widget.currentUserProfile.userId));
                        },
                        icon: const Icon(Icons.close),
                      ))),
              suggestionsCallback: (pattern) async {
                if (pattern.trim().isNotEmpty) {
                  _searchBloc.add(SearchQueryChanged(query: pattern));
                  if (shouldShow) {
                    const limit = 5;
                    final accessToken =
                    await _flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
                    return await _userRepository.searchForUsers(pattern.trim(), accessToken!, limit, ConstantUtils.DEFAULT_OFFSET);
                  } else {
                    return List.empty();
                  }
                }
                else {
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
                        image: ImageUtils.getUserProfileImage(suggestion, 100, 100),
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
            )
        );
      },
    );
  }

  Widget _userSearchBody() {
    return BlocBuilder<UserSearchBloc, UserSearchState>(
      builder: (BuildContext context, UserSearchState state) {// }
        if (state is UserSearchResultsError) {
          return Expanded(child: Center(child: Text(state.error)));
        }
        if (state is UserSearchResultsLoaded) {
          return state.userData.isEmpty
              ? const Expanded(child: Center(child: Text('No Results')))
              : Expanded(
                  child: UserResultsList(
                    userProfiles: state.userData,
                    currentUserProfile: widget.currentUserProfile,
                    fetchMoreResultsCallback: _fetchMoreResultsCallback,
                    doesNextPageExist: state.doesNextPageExist,
                    swipeToDismissUserCallback: null,
                    listHeadingText: "Total Users",
                )
              );
        }
        else {
          if (DeviceUtils.isAppRunningOnMobileBrowser()) {
            return Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.transparent)),
                    child: const Center(child: Text('Search for user by name/username')),
                  ),
                ));
          }
          else {
            return Expanded(child: _skeletonLoadingView());
          }
        }
      },
    );
  }

  _skeletonLoadingView() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SkeletonLoader(
              builder: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                itemCount: 20,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    tileColor: Colors.transparent,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _fetchMoreResultsCallback() {
    final currentState = _searchBloc.state;
    if (currentState is UserSearchResultsLoaded) {
      _searchBloc.add(
          SearchQuerySubmitted(
              query: currentState.query,
              limit: ConstantUtils.DEFAULT_LIMIT,
              offset: currentState.userData.length
          )
      );
    }
  }

  void startFreshSearch(String searchQuery) {
    _searchBloc.add(
        SearchQuerySubmitted(
          query: searchQuery,
          limit: ConstantUtils.DEFAULT_LIMIT,
          offset: ConstantUtils.DEFAULT_OFFSET
        )
    );
  }
}
