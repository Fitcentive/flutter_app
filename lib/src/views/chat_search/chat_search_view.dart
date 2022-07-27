import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_bloc.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_event.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_state.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ChatSearchView extends StatefulWidget {
  static const String routeName = "chat/user/search";

  final PublicUserProfile currentUserProfile;

  const ChatSearchView({Key? key, required this.currentUserProfile}): super(key: key);

  static Route route(PublicUserProfile currentUserProfile) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<ChatSearchBloc>(
                create: (context) => ChatSearchBloc(
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                  userRepository: RepositoryProvider.of<UserRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: ChatSearchView(currentUserProfile: currentUserProfile),
        )
    );
  }


  @override
  State createState() {
    return ChatSearchViewState();
  }

}

class ChatSearchViewState extends State<ChatSearchView> {

  late final ChatSearchBloc _chatSearchBloc;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();
  final _scrollController = ScrollController();

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _chatSearchBloc = BlocProvider.of<ChatSearchBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New message", style: TextStyle(color: Colors.teal)),
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      body: BlocListener<ChatSearchBloc, ChatSearchState>(
        listener: (context, state) {
          if (state is GoToUserChatView) {
            _openUserChatView(state.roomId, state.targetUserProfile);
          }
          else if (state is TargetUserChatNotEnabled) {
            SnackbarUtils.showSnackBar(context, "This user has not enabled chat yet!");
          }
        },
        child: BlocBuilder<ChatSearchBloc, ChatSearchState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _userSearchBar(state),
                _userSearchBody(state)
              ],
            );
          },
        ),
      ),
    );
  }

  _userSearchBody(ChatSearchState state) {
    if (state is ChatSearchStateInitial) {
      return Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.transparent)),
              child: const Center(child: Text('Search for user by name/username')),
            ),
          )
      );
    }
    if (state is ChatSearchResultsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ChatSearchResultsError) {
      return Expanded(child: Center(child: Text(state.error)));
    }
    if (state is ChatSearchResultsLoaded) {
      return state.userData.isEmpty
          ? const Expanded(child: Center(child: Text('No Results')))
          : Expanded(child: _userResultsList(state.userData));
    } else {
      return const Center(child: Text("Error: Something went wrong"));
    }
  }

  _userResultsList(List<PublicUserProfile> userProfiles) {
    return Column(
      children: [
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text(userProfiles.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(child: _searchResults(userProfiles))
      ],
    );
  }

  Widget _searchResults(List<PublicUserProfile> items) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
      subtitle: Text(userProfile.username ?? ""),
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(userProfile, 100, 100),
          ),
        ),
      ),
      onTap: () {
        _chatSearchBloc.add(GetChatRoom(targetUserProfile: userProfile));
      },
    );
  }

  _openUserChatView(String roomId, PublicUserProfile targetUserProfile) {
    Navigator.pushAndRemoveUntil(
        context,
        UserChatView.route(
            currentRoomId: roomId,
            currentUserProfile: widget.currentUserProfile,
            otherUserProfile: targetUserProfile
        ), (route) => true
    );
  }

  _userSearchBar(ChatSearchState state) {
    if (state is ChatSearchResultsLoaded) {
      _searchTextController.text = state.query;
      _searchTextController.selection = TextSelection.collapsed(offset: state.query.length);
    }
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: TypeAheadField<PublicUserProfile>(
          suggestionsBoxController: _suggestionsController,
          debounceDuration: const Duration(milliseconds: 300),
          textFieldConfiguration: TextFieldConfiguration(
              onSubmitted: (value) {},
              autocorrect: false,
              onTap: () => _suggestionsController.toggle(),
              onChanged: (text) {
                if (text.isNotEmpty) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    _chatSearchBloc.add(ChatSearchQueryChanged(query: text));
                  });
                }
              },
              autofocus: true,
              controller: _searchTextController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Search by name/username",
                  suffixIcon: IconButton(
                    onPressed: () {
                      _suggestionsController.close();
                      _chatSearchBloc.add(const ChatSearchQueryChanged(query: ""));
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (pattern)  {
            return List.empty();
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
          onSuggestionSelected: (suggestion) {},
          hideOnEmpty: true,
        )
    );
  }

}