import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class UserChatView extends StatefulWidget {
  static const String routeName = "chat/user";

  final String currentRoomId;
  final PublicUserProfile currentUserProfile;
  final PublicUserProfile otherUserProfile;

  static Route route({
    required String currentRoomId,
    required PublicUserProfile currentUserProfile,
    required PublicUserProfile otherUserProfile,
  }) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
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
  static const int scrollThreshold = 600;

  final ScrollController _scrollController = ScrollController();

  late final types.User _currentUser;
  late final types.User _otherUser;

  bool isDraftMessageEmpty = true;
  bool isRequestingMoreData = false;

  final joinRef = const Uuid().v4();

  List<types.Message> _previousMessages = [];
  List<types.Message> _newMessages = [];

  late final UserChatBloc _userChatBloc;

  @override
  void dispose() {
    _userChatBloc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _currentUser = types.User(
      id: widget.currentUserProfile.userId,
      firstName: widget.currentUserProfile.firstName,
      lastName: widget.currentUserProfile.lastName,
      imageUrl: ImageUtils.getFullImageUrl(widget.currentUserProfile.photoUrl, 100, 100),
    );
    _otherUser = types.User(
      id: widget.otherUserProfile.userId,
      firstName: widget.otherUserProfile.firstName,
      lastName: widget.otherUserProfile.lastName,
      imageUrl: ImageUtils.getFullImageUrl(widget.otherUserProfile.photoUrl, 100, 100),
    );

    _userChatBloc = BlocProvider.of<UserChatBloc>(context);
    _userChatBloc.add(ConnectWebsocketAndFetchHistoricalChats(
        roomId: widget.currentRoomId,
        currentUserId: widget.currentUserProfile.userId
    ));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
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
              child: Text(
                StringUtils.getUserNameFromUserProfile(widget.otherUserProfile),
                style: const TextStyle(color: Colors.teal),
              ),
            )
          ],
        ),
      ),
      body: BlocBuilder<UserChatBloc, UserChatState>(
        builder: (context, state) {
          if (state is HistoricalChatsFetched) {
            isRequestingMoreData = false;
            _previousMessages = List<types.Message>.from(state.messages.map((msg) => types.TextMessage(
              author: msg.senderId == widget.currentUserProfile.userId ? _currentUser : _otherUser,
              createdAt: msg.createdAt.millisecondsSinceEpoch,
              id: msg.id,
              text: msg.text,
            )));

            // Cannot simply add after, need to sort
            for (var msg in _newMessages.reversed) {
              _previousMessages.insert(0, msg);
            }

            // todo -  this could be a problem at scale
            _previousMessages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

            return Scrollbar(
              controller: _scrollController,
              child: Chat(
                scrollController: _scrollController,
                messages: _previousMessages,
                onTextChanged: _handleTextChanged,
                onAttachmentPressed: _handleAttachmentPressed,
                onMessageTap: _handleMessageTap,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                showUserAvatars: true,
                showUserNames: true,
                user: _currentUser,
                onEndReached: () async {
                  if (!isRequestingMoreData) {
                    isRequestingMoreData = true;
                    _userChatBloc.add(FetchMoreChatData(
                        roomId: widget.currentRoomId,
                        currentUserId: widget.currentUserProfile.userId,
                        sentBefore: _previousMessages.last.createdAt!
                    ));
                  }
                },
              ),
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      )
    );
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    print("Something here");
    // final result = await FilePicker.platform.pickFiles(
    //   type: FileType.any,
    // );
    //
    // if (result != null && result.files.single.path != null) {
    //   final message = types.FileMessage(
    //     author: _user,
    //     createdAt: DateTime.now().millisecondsSinceEpoch,
    //     id: const Uuid().v4(),
    //     mimeType: lookupMimeType(result.files.single.path!),
    //     name: result.files.single.name,
    //     size: result.files.single.size,
    //     uri: result.files.single.path!,
    //   );
    //
    //   _addMessage(message);
    // }
  }

  void _handleImageSelection() async {
    print("Something here as well");
    // final result = await ImagePicker().pickImage(
    //   imageQuality: 70,
    //   maxWidth: 1440,
    //   source: ImageSource.gallery,
    // );
    //
    // if (result != null) {
    //   final bytes = await result.readAsBytes();
    //   final image = await decodeImageFromList(bytes);
    //
    //   final message = types.ImageMessage(
    //     author: _user,
    //     createdAt: DateTime.now().millisecondsSinceEpoch,
    //     height: image.height.toDouble(),
    //     id: const Uuid().v4(),
    //     name: result.name,
    //     size: bytes.length,
    //     uri: result.path,
    //     width: image.width.toDouble(),
    //   );
    //
    //   _addMessage(message);
    // }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    print("PREVIEW DATA FETFCHED SON");
    // final index = _messages.indexWhere((element) => element.id == message.id);
    // final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
    //   previewData: previewData,
    // );

    // setState(() {
    //   _messages[index] = updatedMessage;
    // });
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          // final index =
          // _messages.indexWhere((element) => element.id == message.id);
          // final updatedMessage =
          // (_messages[index] as types.FileMessage).copyWith(
          //   isLoading: true,
          // );

          // setState(() {
          //   _messages[index] = updatedMessage;
          // });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          // final index =
          // _messages.indexWhere((element) => element.id == message.id);
          // final updatedMessage =
          // (_messages[index] as types.FileMessage).copyWith(
          //   isLoading: null,
          // );
          //
          // setState(() {
          //   _messages[index] = updatedMessage;
          // });
        }
      }

      // await OpenFile.open(localPath);
    }
  }

  void _handleSendPressed(types.PartialText message) {
    isDraftMessageEmpty = true;
    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage, message.text);
  }

  void _handleTextChanged(String messageDraft) {
    if (messageDraft.isNotEmpty && isDraftMessageEmpty) {
      isDraftMessageEmpty = false;
      _userChatBloc.add(CurrentUserTypingStarted(widget.currentRoomId, widget.currentUserProfile.userId));
    }
    else if (messageDraft.isEmpty && !isDraftMessageEmpty) {
      isDraftMessageEmpty = true;
      _userChatBloc.add(CurrentUserTypingStopped(widget.currentRoomId, widget.currentUserProfile.userId));
    }

  }

  void _addMessage(types.Message message, String textMessage) {
    setState(() {
      _newMessages.insert(0, message);
    });
    _userChatBloc.add(
        AddMessageToChatRoom(
            roomId: widget.currentRoomId,
            text: textMessage,
            userId: widget.currentUserProfile.userId
        )
    );
  }

}