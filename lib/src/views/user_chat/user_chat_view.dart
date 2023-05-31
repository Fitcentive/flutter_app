import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_chat/detailed_chat_view.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
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
  final List<PublicUserProfile> otherUserProfiles;

  static Route route({
    required String currentRoomId,
    required PublicUserProfile currentUserProfile,
    required List<PublicUserProfile> otherUserProfiles,
  }) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<UserChatBloc>(
                create: (context) => UserChatBloc(
                  meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
                  userRepository: RepositoryProvider.of<UserRepository>(context),
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: UserChatView(
              currentRoomId: currentRoomId,
              otherUserProfiles: otherUserProfiles,
              currentUserProfile: currentUserProfile
          ),
        )
    );
  }

  const UserChatView({
    Key? key,
    required this.currentRoomId,
    required this.currentUserProfile,
    required this.otherUserProfiles
  }): super(key: key);


  @override
  State createState() {
    return UserChatViewState();
  }

}

class UserChatViewState extends State<UserChatView> {
  static const int scrollThreshold = 600;

  final ScrollController _scrollController = ScrollController();

  types.User? _currentUser;
  List<types.User>? _otherUsers;

  bool isDraftMessageEmpty = true;
  bool isRequestingMoreData = false;

  final joinRef = const Uuid().v4();

  String lastReadMessageId = "";
  List<types.Message> _previousMessages = [];
  List<types.Message> _newMessages = [];

  late final UserChatBloc _userChatBloc;

  String chatTitle = "";

  @override
  void dispose() {
    _userChatBloc.dispose();
    _scrollController.dispose();
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
    _otherUsers = widget.otherUserProfiles.map((e) => types.User(
      id: e.userId,
      firstName: e.firstName,
      lastName: e.lastName,
      imageUrl: ImageUtils.getFullImageUrl(e.photoUrl, 100, 100),
    )).toList();

    _userChatBloc = BlocProvider.of<UserChatBloc>(context);
    _userChatBloc.add(ConnectWebsocketAndFetchHistoricalChats(
        roomId: widget.currentRoomId,
        currentUserId: widget.currentUserProfile.userId
    ));

  }

  _generateChatPicture(HistoricalChatsFetched state) {
    if (state.chatRoomUserProfiles.length > 2) {
      return InkWell(
        onTap: () {
          _goToDetailedChatView(state);
        },
        child: Container(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: ImageUtils.getUserProfileImage(state.chatRoomUserProfiles.first, 100, 100),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: ImageUtils.getUserProfileImage(state.chatRoomUserProfiles[1], 100, 100),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    else {
      return CircleAvatar(
        radius: 20,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(widget.otherUserProfiles.first, 100, 100),
          ),
        ),
      );
    }
  }

  _generateChatPictureInitial() {
    if (widget.otherUserProfiles.length > 1) {
      return Container(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(widget.otherUserProfiles.first, 100, 100),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(widget.otherUserProfiles[1], 100, 100),
                ),
              ),
            ),
          ],
        ),
      );
    }
    else {
      return CircleAvatar(
        radius: 20,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(widget.otherUserProfiles.first, 100, 100),
          ),
        ),
      );
    }
  }

  _generateChatTitle(HistoricalChatsFetched state) {
    setState(() {
      if (state.chatRoomUserProfiles.length > 2) {
        chatTitle = state.currentChatRoom.roomName;
      }
      else {
        chatTitle = StringUtils.getUserNameFromUserProfile(widget.otherUserProfiles.first);
      }
    });
  }

  _getChatMessageAuthor(String senderId, HistoricalChatsFetched state) {
    if (senderId == widget.currentUserProfile.userId) {
      return _currentUser;
    }
    else {
      return _otherUsers!
          .firstWhere((element) => state.allMessagingUserProfiles.firstWhere((element) => element.userId == senderId).userId == element.id);
    }
  }

  _redoOtherUsers(HistoricalChatsFetched state) {
    setState(() {
      _otherUsers = state.allMessagingUserProfiles
          .where((element) => element.userId != widget.currentUserProfile.userId)
          .map((e) => types.User(
        id: e.userId,
        firstName: e.firstName,
        lastName: e.lastName,
        imageUrl: ImageUtils.getFullImageUrl(e.photoUrl, 100, 100),
      )).toList();
    });
  }

  _goToDetailedChatView(HistoricalChatsFetched state) {
    Navigator.push(context, DetailedChatView.route(
        associatedMeetup: state.associatedMeetup,
        currentChatRoom: state.currentChatRoom,
        currentUserProfile: widget.currentUserProfile,
        otherUserProfiles: List.from(state.chatRoomUserProfiles)..removeWhere((element) => element.userId == widget.currentUserProfile.userId),
    )).then((value) {
      _userChatBloc.add(ConnectWebsocketAndFetchHistoricalChats(
          roomId: widget.currentRoomId,
          currentUserId: widget.currentUserProfile.userId
      ));
    });
  }

  _generateTitle(HistoricalChatsFetched state) {
    return InkWell(
      onTap: () {
        // Go to detailed chat view
        _goToDetailedChatView(state);
      },
      child: Text(
        chatTitle,
        style: const TextStyle(color: Colors.teal),
      ),
    );
  }

  _updateUserChatRoomLastSeen() {
    _userChatBloc.add(UpdateCurrentUserChatRoomLastSeen(roomId: widget.currentRoomId));
  }

  // todo - nasty bug here, user msgs are sometimes is 2x/4x, especially right after adding new person to chat
  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
        bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
        title: BlocBuilder<UserChatBloc, UserChatState>(
          builder: (context, state) {
            if (state is HistoricalChatsFetched) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _generateChatPicture(state),
                  WidgetUtils.spacer(10),
                  _generateTitle(state),
                ],
              );
            }
            else {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _generateChatPictureInitial(),
                  WidgetUtils.spacer(10),
                  Expanded(
                    child: Text(
                      chatTitle,
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          _updateUserChatRoomLastSeen();
          return true;
        },
        child: BlocListener<UserChatBloc, UserChatState>(
          listener: (context, state) {
            if (state is HistoricalChatsFetched) {
              _generateChatTitle(state);
              _redoOtherUsers(state);
            }
          },
          child: BlocBuilder<UserChatBloc, UserChatState>(
            builder: (context, state) {
              if (state is HistoricalChatsFetched) {
                isRequestingMoreData = false;
                _previousMessages = List<types.Message>.from(state.messages.map((msg) => types.TextMessage(
                  author: _getChatMessageAuthor(msg.senderId, state),
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

                if (state.userLastSeen != null) {
                  final templastReadMessageId = _previousMessages
                      .lastWhere(
                          (element) => DateTime
                              .fromMillisecondsSinceEpoch(element.createdAt!)
                              .compareTo(state.userLastSeen!.lastSeen) >= 0 && element.author.id != _currentUser!.id,
                  orElse: () {
                            return types.TextMessage(
                              author: _currentUser!,
                              id: "random_unused_id",
                              text: "msg.text",
                            );
                  })
                      .id;

                  if (templastReadMessageId != "random_unused_id") {
                    final indexOf = _previousMessages[_previousMessages.indexWhere((element) => element.id == templastReadMessageId)];
                    if (indexOf != _previousMessages.length - 1) {
                      lastReadMessageId = _previousMessages[_previousMessages.indexWhere((element) => element.id == templastReadMessageId) + 1].id;
                    }
                  }

                }
                else {
                  if (_previousMessages.isNotEmpty) {
                    lastReadMessageId = _previousMessages.last.id;
                  }
                }


                return Column(
                  children: WidgetUtils.skipNulls([
                    _renderMeetupMiniCard(state),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: _renderChatView(),
                      ),
                    )
                  ]),
                );
              }
              else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      )
    );
  }

  _goToDetailedMeetupView(String meetupId) {
    Navigator.push(
        context,
        DetailedMeetupView.route(meetupId: meetupId, currentUserProfile: widget.currentUserProfile)
    );
  }

  _renderMeetupMiniCard(HistoricalChatsFetched state) {
    if (state.associatedMeetup != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: ListTile(
          onTap: () {
            _goToDetailedMeetupView(state.associatedMeetup!.id);
          },
          tileColor: Colors.teal,
          title: Center(
            child: Text(
                state.associatedMeetup!.name ?? "Unnamed Meetup",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16
              ),
            ),
          ),
          subtitle: const Center(
            child: Text(
              "This chat is associated with a meetup!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12
              ),
            ),
          ),
        ),
      );
    }
  }

  _renderChatView() {
    return Chat(
      // scrollController: _scrollController,
      messages: _previousMessages,
      inputOptions: InputOptions(
        onTextChanged: _handleTextChanged,
      ),
      scrollToUnreadOptions: ScrollToUnreadOptions(
        lastReadMessageId: lastReadMessageId,
        scrollOnOpen: true,
      ),
      onAttachmentPressed: _handleAttachmentPressed,
      onMessageTap: _handleMessageTap,
      onPreviewDataFetched: _handlePreviewDataFetched,
      onSendPressed: _handleSendPressed,
      showUserAvatars: true,
      showUserNames: true,
      user: _currentUser!,
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
      author: _currentUser!,
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