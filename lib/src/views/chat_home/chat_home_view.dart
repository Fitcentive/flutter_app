import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    _chatBloc = BlocProvider.of<ChatHomeBloc>(context);
    _chatBloc.add(FetchUserRooms(userId: widget.currentUserProfile.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ChatHomeBloc, ChatHomeState>(
        builder: (context, state) {
          if (state is UserRoomsLoaded) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchBar(),
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

  _searchBar() {
    return InkWell(
      onTap: () {
        Navigator.pushAndRemoveUntil<void>(
            context,
            ChatSearchView.route(widget.currentUserProfile), (route) => true
        );
      },
      child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Stack(
                      children: const [
                        Icon(
                          Icons.search,
                          color: Colors.teal,
                        ),
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: Center(
                            child: Text("Search", style: TextStyle(fontSize: 15)),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )
          )
      ),
    );
  }

  _chatList(UserRoomsLoaded state) {
    return RefreshIndicator(
        onRefresh: _pullRefresh,
        child: Scrollbar(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.rooms.length,
            itemBuilder: (context, index) {
              final currentChatRoom = state.rooms[index];
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