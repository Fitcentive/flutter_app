import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/image_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_bloc.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_event.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_state.dart';
import 'package:flutter_app/src/views/chat_search/chat_search_view.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ChatHomeView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const ChatHomeView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<ChatHomeBloc>(
          create: (context) => ChatHomeBloc(
            chatRepository: RepositoryProvider.of<ChatRepository>(context),
            imageRepository: RepositoryProvider.of<ImageRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: ChatHomeView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return ChatHomeViewState();
  }
}

class ChatHomeViewState extends State<ChatHomeView> {

  late final ChatHomeBloc _chatBloc;

  bool _isFloatingButtonVisible = true;
  final _scrollController = ScrollController();

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _chatBloc = BlocProvider.of<ChatHomeBloc>(context);
    _chatBloc.add(FetchUserRooms(userId: widget.currentUserProfile.userId));

    _scrollController.addListener(_onScroll);
  }

  _goToChatSearchView() {
    Navigator.pushAndRemoveUntil<void>(
        context,
        ChatSearchView.route(widget.currentUserProfile), (route) => true
    );
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      // Handle floating action button visibility
      if(_scrollController.position.userScrollDirection == ScrollDirection.reverse){
        if(_isFloatingButtonVisible == true) {
          setState((){
            _isFloatingButtonVisible = false;
          });
        }
      } else {
        if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
          if (_isFloatingButtonVisible == false) {
            setState(() {
              _isFloatingButtonVisible = true;
            });
          }
        }
      }

    }
  }

  _animatedButton() {
    return AnimatedOpacity(
      opacity: _isFloatingButtonVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: _isFloatingButtonVisible,
        child: FloatingActionButton(
          heroTag: "MeetupHomeViewCreateNewMeetupButton",
          onPressed: () {
            _goToChatSearchView();
          },
          tooltip: 'Create new meetup!',
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _animatedButton(),
      body: BlocBuilder<ChatHomeBloc, ChatHomeState>(
        builder: (context, state) {
          if (state is UserRoomsLoaded) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _searchBar(),
                _filterSearchBar(),
                Expanded(
                    child: _chatList(state)
                )
              ],
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  _filterSearchBar() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: TypeAheadField<PublicUserProfile>(
          suggestionsBoxController: _suggestionsController,
          debounceDuration: const Duration(milliseconds: 300),
          textFieldConfiguration: TextFieldConfiguration(
              onSubmitted: (value) {},
              autocorrect: false,
              onTap: () => _suggestionsController.toggle(),
              onChanged: (text) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  _chatBloc.add(FilterSearchQueryChanged(query: text));
                });

              },
              autofocus: true,
              controller: _searchTextController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Search by user, conversation... ",
                  suffixIcon: IconButton(
                    onPressed: () {
                      _suggestionsController.close();
                      _searchTextController.text = "";
                      _chatBloc.add(const FilterSearchQueryChanged(query: ""));
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (text)  {
            // _exerciseSearchBloc.add(FilterSearchQueryChanged(searchQuery: text.trim()));
            return List.empty();
          },
          itemBuilder: (context, suggestion) {
            final s = suggestion;
            // This is unused but needed, we will keep it in for now
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

  _chatList(UserRoomsLoaded state) {
    if (state.filteredRooms.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _pullRefresh,
        child: Scrollbar(
          controller: _scrollController,
          child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: state.filteredRooms.length,
              itemBuilder: (context, index) {
                final currentChatRoom = state.filteredRooms[index];
                final otherUserIdsInChatRoom = currentChatRoom
                    .userIds
                    .where((element) => element != widget.currentUserProfile.userId)
                    .toList();

                final List<PublicUserProfile> otherUserProfiles = state
                    .userIdProfileMap
                    .entries
                    .where((element) => otherUserIdsInChatRoom.contains(element.value.userId))
                    .map((e) => e.value).toList();

                return ListTile(
                    title: Text(
                      currentChatRoom.isGroupChat ? currentChatRoom.roomName : StringUtils.getUserNameFromUserProfile(otherUserProfiles.first),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600
                      ),
                    ),
                    subtitle: Text(currentChatRoom.mostRecentMessage),
                    leading: GestureDetector(
                      onTap: () async {
                        _openUserChatView(currentChatRoom, otherUserProfiles);
                      },
                      child: _generateChatPicture(currentChatRoom, widget.currentUserProfile.userId, otherUserIdsInChatRoom, state.userIdProfileMap),
                    ),
                    onTap: () {
                      _openUserChatView(currentChatRoom, otherUserProfiles);
                    }
                );
              }
          ),
        ),
      );
    }
    else {
      return const Center(
        child: Text(
            "No results... refine search query"
        ),
      );
    }
  }

  _generateChatPicture(
      ChatRoomWithMostRecentMessage currentChatRoom,
      String currentUserId,
      List<String> otherUserIdsInChatRoom,
      Map<String, PublicUserProfile> userIdProfileMap,
  ) {
    if (currentChatRoom.isGroupChat) {
      final otherUserProfilesInThisChat =
        userIdProfileMap.entries.where((element) => otherUserIdsInChatRoom.contains(element.key)).map((e) => e.value).toList();
      // Group chat has minimum 3 people, HARD RESTRICTION!
      return Container(
        width: 50,
        height: 50,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 32.5,
                height: 32.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(otherUserProfilesInThisChat.first, 100, 100),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 32.5,
                height: 32.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(otherUserProfilesInThisChat[1], 100, 100),
                ),
              ),
            ),
          ],
        ),
      );
    }
    else {
      final otherUserProfile = userIdProfileMap[otherUserIdsInChatRoom.first];
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: ImageUtils.getUserProfileImage(otherUserProfile, 100, 100),
        ),
      );
    }
  }

  _openUserChatView(ChatRoomWithMostRecentMessage room, List<PublicUserProfile> otherUserProfiles) {
    Navigator.pushAndRemoveUntil(
        context,
        UserChatView.route(
            currentRoomId: room.roomId,
            currentUserProfile: widget.currentUserProfile,
            otherUserProfiles: otherUserProfiles
        ),
            (route) => true
    );
  }

  Future<void> _pullRefresh() async {
    _chatBloc.add(FetchUserRooms(userId: widget.currentUserProfile.userId));
  }

}