import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/chat_room_updated_stream_repository.dart';
import 'package:flutter_app/src/models/chats/chat_room_with_most_recent_message.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_bloc.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_event.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_state.dart';
import 'package:flutter_app/src/views/chat_search/chat_search_view.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class ChatHomeView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const ChatHomeView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<ChatHomeBloc>(
          create: (context) => ChatHomeBloc(
            chatRepository: RepositoryProvider.of<ChatRepository>(context),
            imageRepository: RepositoryProvider.of<PublicGatewayRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            chatRoomUpdatedStreamRepository: RepositoryProvider.of<ChatRoomUpdatedStreamRepository>(context),
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
  static const double _scrollThreshold = 350.0;

  late final ChatHomeBloc _chatBloc;

  bool isDataBeingRequested = false;
  bool shouldHideKeyboardManually = true;

  bool _isFloatingButtonVisible = true;
  final _scrollController = ScrollController();

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  Timer? _debounce;

  @override
  void dispose() {
    _chatBloc.dispose();
    _searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _chatBloc = BlocProvider.of<ChatHomeBloc>(context);
    _fetchDefaultChatRooms();
    _chatBloc.add(const TrackViewChatHomeEvent());

    _scrollController.addListener(_onScroll);
  }

  _goToChatSearchView() {
    Navigator.push<void>(
        context,
        ChatSearchView.route(widget.currentUserProfile),
    ).then((value) {
      _fetchDefaultChatRooms();
    });
  }

  _fetchMoreChatRooms() {
    _chatBloc.add(
        FetchMoreUserRooms(
          userId: widget.currentUserProfile.userId,
          limit: ConstantUtils.DEFAULT_CHAT_ROOMS_LIMIT,
        )
    );
  }

  _fetchDefaultChatRooms() {
    _chatBloc.add(
        FetchUserRooms(
          userId: widget.currentUserProfile.userId,
          limit: ConstantUtils.DEFAULT_CHAT_ROOMS_LIMIT,
          offset: ConstantUtils.DEFAULT_OFFSET,
        )
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

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        isDataBeingRequested = true;
        _fetchMoreChatRooms();
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
          heroTag: "ChatHomeViewCreateNewChatButton",
          onPressed: () {
            _goToChatSearchView();
          },
          tooltip: 'Create new chat!',
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shouldHideKeyboardManually) {
      KeyboardUtils.hideKeyboard(context);
    }
    return Scaffold(
      floatingActionButton: _animatedButton(),
      body: BlocBuilder<ChatHomeBloc, ChatHomeState>(
        builder: (context, state) {
          if (state is UserRoomsLoaded) {
            isDataBeingRequested = false;
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
            if (DeviceUtils.isAppRunningOnMobileBrowser()) {
              return WidgetUtils.progressIndicator();
            }
            else {
              return _skeletonLoadingView();
            }
          }
        },
      ),
    );
  }

  _skeletonLoadingView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SkeletonLoader(
            builder: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _filterSearchBar(),
                _chatListStubs()
              ],
            ),
          ),
        ],
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
              onTap: () {
                // _suggestionsController.toggle();
                shouldHideKeyboardManually = false;
              },
              onChanged: (text) {
                shouldHideKeyboardManually = false;
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
                  hintStyle: const TextStyle(color: Colors.grey),
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

  _chatListStubs() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: 20,
        itemBuilder: (context, index) {
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
              leading: _generateChatPicture(
                  false,
                  widget.currentUserProfile.userId,
                  [widget.currentUserProfile.userId],
                  {
                    widget.currentUserProfile.userId : widget.currentUserProfile
                  }),
          );
        }
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
              itemCount: state.doesNextPageExist ? state.filteredRooms.length + 1 : state.filteredRooms.length,
              itemBuilder: (context, index) {
                if (index >= state.filteredRooms.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                else {
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
                      tileColor: _isMessageUnread(state, currentChatRoom) ? Colors.grey.shade200 : Colors.transparent,
                      title: Text(
                        currentChatRoom.isGroupChat ? currentChatRoom.roomName : StringUtils.getUserNameFromUserProfile(otherUserProfiles.first),
                        style: TextStyle(
                          fontWeight: _isMessageUnread(state, currentChatRoom) ? FontWeight.bold : FontWeight.w500,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                        child: Text(
                          StringUtils.truncateLongString(currentChatRoom.mostRecentMessage),
                          style: TextStyle(
                              fontWeight: _isMessageUnread(state, currentChatRoom) ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                      ),
                      leading: GestureDetector(
                        onTap: () async {
                          _openUserChatView(currentChatRoom, otherUserProfiles);
                        },
                        child: _generateChatPicture(currentChatRoom.isGroupChat, widget.currentUserProfile.userId, otherUserIdsInChatRoom, state.userIdProfileMap),
                      ),
                      onTap: () {
                        _openUserChatView(currentChatRoom, otherUserProfiles);
                      }
                  );
                }
              }
          ),
        ),
      );
    }
    else {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Text(
              "No chats found... refine search query or get started by creating one!",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  _isMessageUnread(UserRoomsLoaded state, ChatRoomWithMostRecentMessage currentChatRoom) {
    final res = (state.roomUserLastSeenMap[currentChatRoom.roomId]?.compareTo(
        currentChatRoom.mostRecentMessageTime.toUtc()) ?? -1);
    return res <= 0;
  }

  _generateChatPicture(
      bool isGroupChat,
      String currentUserId,
      List<String> otherUserIdsInChatRoom,
      Map<String, PublicUserProfile> userIdProfileMap,
  ) {
    if (isGroupChat) {
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
    Navigator.push(
        context,
        UserChatView.route(
            currentRoomId: room.roomId,
            currentUserProfile: widget.currentUserProfile,
            otherUserProfiles: otherUserProfiles
        ),
    ).then((value) {
      shouldHideKeyboardManually = true;
      _fetchDefaultChatRooms();
    });
  }

  Future<void> _pullRefresh() async {
    shouldHideKeyboardManually = true;
    _fetchDefaultChatRooms();
  }

}