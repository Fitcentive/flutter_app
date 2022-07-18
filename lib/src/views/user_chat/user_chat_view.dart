import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_bloc.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_event.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class UserChatView extends StatefulWidget {
  final String currentRoomId;
  final PublicUserProfile currentUserProfile;
  final PublicUserProfile otherUserProfile;

  static Route route({
    required String currentRoomId,
    required PublicUserProfile currentUserProfile,
    required PublicUserProfile otherUserProfile,
  }) {
    return MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<UserChatBloc>(
                create: (context) => UserChatBloc(
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: UserChatView(
              currentRoomId: currentRoomId,
              otherUserProfile: otherUserProfile,
              currentUserProfile: currentUserProfile
          ),
        )
    );
  }

  const UserChatView({
    Key? key,
    required this.currentRoomId,
    required this.currentUserProfile,
    required this.otherUserProfile
  }): super(key: key);


  @override
  State createState() {
    return UserChatViewState();
  }

}

class UserChatViewState extends State<UserChatView> {

  late final types.User _currentUser;
  late final types.User _otherUser;

  final msg = types.TextMessage(
    author: types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ad'),
    createdAt: DateTime.now().millisecondsSinceEpoch,
    id: const Uuid().v4(),
    text: "This is a test",
  );

  List<types.Message> _previousMessages = [];
  List<types.Message> _newMessages = [];

  late final UserChatBloc _userChatBloc;

  @override
  void initState() {
    super.initState();

    _currentUser = types.User(
      id: widget.currentUserProfile.userId,
      firstName: widget.currentUserProfile.firstName,
      lastName: widget.currentUserProfile.firstName,
      imageUrl: ImageUtils.getFullImageUrl(widget.currentUserProfile.photoUrl, 100, 100),
    );
    _otherUser = types.User(
      id: widget.otherUserProfile.userId,
      firstName: widget.otherUserProfile.firstName,
      lastName: widget.otherUserProfile.firstName,
      imageUrl: ImageUtils.getFullImageUrl(widget.otherUserProfile.photoUrl, 100, 100),
    );

    _userChatBloc = BlocProvider.of<UserChatBloc>(context);
    _userChatBloc.add(FetchHistoricalChats(roomId: widget.currentRoomId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(widget.otherUserProfile, 100, 100),
                ),
              ),
            ),
            WidgetUtils.spacer(10),
            Expanded(
              child: Text(StringUtils.getUserNameFromUserProfile(widget.otherUserProfile)),
            )
          ],
        ),
      ),
      body: BlocBuilder<UserChatBloc, UserChatState>(
        builder: (context, state) {
          if (state is HistoricalChatsFetched) {
            _previousMessages = List<types.Message>.from(state.messages.map((msg) => types.TextMessage(
              author: msg.senderId == widget.currentUserProfile.userId ? _currentUser : _otherUser,
              createdAt: msg.createdAt.millisecondsSinceEpoch,
              id: msg.id,
              text: msg.text,
            )));
            for (var msg in _newMessages.reversed) {
              _previousMessages.insert(0, msg);
            }

            return Chat(
              messages: _previousMessages,
              // onAttachmentPressed: _handleAtachmentPressed,
              // onMessageTap: _handleMessageTap,
              // onPreviewDataFetched: _handlePreviewDataFetched,
              onSendPressed: _handleSendPressed,
              showUserAvatars: true,
              showUserNames: true,
              user: _currentUser,
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

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _addMessage(types.Message message) {
    setState(() {
        print("SET STATE IS CALLED HERE");
      _newMessages.insert(0, message);
    });
  }

}