import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/search/bloc/search_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/search_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class UserSearchBar extends StatefulWidget {

  const UserSearchBar({Key? key}) : super(key: key);

  @override
  State createState() {
    return UserSearchBarState();
  }
}

class UserSearchBarState extends State<UserSearchBar> with AutomaticKeepAliveClientMixin {

  @override
  bool wantKeepAlive = true;

  late final SearchBloc _searchBloc;
  late final UserRepository _userRepository;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  bool shouldShow = false;

  @override
  void initState() {
    super.initState();
    _searchBloc = BlocProvider.of<SearchBloc>(context);
    _userRepository = RepositoryProvider.of<UserRepository>(context);
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: TypeAheadField<UserProfile>(
          hideSuggestionsOnKeyboardHide: false,
          suggestionsBoxController: _suggestionsController,
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
                      startFreshSearch(_searchTextController.value.text);
                    },
                    icon: const Icon(Icons.search),
                  )
              )
          ),
          suggestionsCallback: (pattern) {
            if(shouldShow) {
             // todo - get suggestions
             return List.empty();
            } else {
              return List.empty();
            }
          },
          itemBuilder: (context, suggestion) {
            final s = suggestion;
            return ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text("${s.firstName ?? ""} ${s.lastName ?? ""}"),
              subtitle: const Text("Username goes here"),
            );
          },
          onSuggestionSelected: (suggestion) {
            _searchTextController.text = suggestion.toString();
            startFreshSearch(_searchTextController.value.text);
          },
          hideOnEmpty: true,
        )
    );
  }

  void startFreshSearch(String searchQuery) {
    _searchBloc.add(SearchQuerySubmitted(query: searchQuery));
  }

}