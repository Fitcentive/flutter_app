import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/repos/rest/image_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_bloc.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_event.dart';
import 'package:flutter_app/src/views/chat_home/bloc/chat_home_state.dart';
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
            return ListView.builder(
                shrinkWrap: true,
                itemCount: state.rooms.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InkWell(
                      onTap: () {
                        print("No search implementation yet");
                      },
                      child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Container(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.search,
                                    color: Colors.teal,
                                  ),
                                  Expanded(
                                      child: Center(
                                        child: Text("Search"),
                                      )
                                  )
                                ],
                              )
                          )
                      ),
                    );
                  }
                  else {
                    final currentChatRoom = state.rooms[index - 1];
                    final otherUserInChatRoom = currentChatRoom.userIds.firstWhere((element) => element != widget.currentUserProfile.userId);
                    final otherUserProfile = state.userIdProfileMap[otherUserInChatRoom];

                    return ListTile(
                      title: Text(
                        StringUtils.getUserNameFromUserProfile(otherUserProfile),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      subtitle: Text(currentChatRoom.mostRecentMessage),
                      leading: GestureDetector(
                        onTap: () async {
                          _openUserChatView(currentChatRoom.roomId, otherUserProfile!);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: ImageUtils.getUserProfileImage(otherUserProfile, 100, 100),
                          ),
                        ),
                      ),
                      onTap: () {
                        _openUserChatView(currentChatRoom.roomId, otherUserProfile!);
                      }
                    );
                  }
                }
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

  _openUserChatView(String roomId, PublicUserProfile otherUserProfile) {
    Navigator.pushAndRemoveUntil(
        context,
        UserChatView.route(
            currentRoomId: roomId,
            currentUserProfile: widget.currentUserProfile,
            otherUserProfile: otherUserProfile
        ),
            (route) => true
    );
  }


}