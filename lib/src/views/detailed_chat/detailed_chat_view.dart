import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/models/chats/chat_room.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_bloc.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_event.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedChatView extends StatefulWidget {
  static const String routeName = "chat/user/info";

  final ChatRoom currentChatRoom;
  final PublicUserProfile currentUserProfile;
  final List<PublicUserProfile> otherUserProfiles;

  static Route route({
    required ChatRoom currentChatRoom,
    required PublicUserProfile currentUserProfile,
    required List<PublicUserProfile> otherUserProfiles,
  }) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DetailedChatBloc>(
                create: (context) => DetailedChatBloc(
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                )),
          ],
          child: DetailedChatView(
              currentChatRoom: currentChatRoom,
              otherUserProfiles: otherUserProfiles,
              currentUserProfile: currentUserProfile
          ),
        )
    );
  }

  const DetailedChatView({
    Key? key,
    required this.currentChatRoom,
    required this.currentUserProfile,
    required this.otherUserProfiles
  }): super(key: key);


  @override
  State createState() {
    return DetailedChatViewState();
  }
}

class DetailedChatViewState extends State<DetailedChatView> {

  late DetailedChatBloc _detailedChatBloc;

  late Widget currentChatTitleWidget;
  late String currentChatTitleEdited;
  bool isEditingChatTitle = false;
  Icon currentChatTitleIcon = const Icon(
    Icons.edit,
    size: 20,
    color: Colors.teal,
  );

  bool isEditParticipantsButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    currentChatTitleEdited = widget.currentChatRoom.name;
    currentChatTitleWidget = Text(
      widget.currentChatRoom.name,
      style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.teal
      ),
    );

    _detailedChatBloc = BlocProvider.of<DetailedChatBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(visible: isEditParticipantsButtonEnabled, child: _addParticipantsToChatButton()),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
        title: const Text('Chat Info', style: TextStyle(color: Colors.teal),),
      ),
      body: Scrollbar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(5),
            _renderChatTitle(),
            WidgetUtils.spacer(10),
            _renderChatPictures(),
            WidgetUtils.spacer(10),
            _renderEditParticipantsButtonIfNeeded(),
            WidgetUtils.spacer(5),
            _renderHintIfNeeded(),
            WidgetUtils.spacer(10),
            WidgetUtils.spacer(2.5),
            _renderChatParticipants(),
          ]),
        ),
      ),
    );
  }

  _addParticipantsToChatButton() {
    return FloatingActionButton(
      heroTag: "DetailedChatViewAddParticipantToChatButton",
      onPressed: () {
        // Do something here
      },
      tooltip: 'Add participants to conversation!',
      backgroundColor: Colors.teal,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  _renderChatParticipants() {
    final plainList = UserResultsList(
      userProfiles: [widget.currentUserProfile, ...widget.otherUserProfiles],
      currentUserProfile: widget.currentUserProfile,
      doesNextPageExist: false,
      fetchMoreResultsCallback:  () {},
      shouldListBeSwipable: isEditParticipantsButtonEnabled,
      swipeToDismissUserCallback: _swipeToDismissUserCallback,
    );

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
            border: Border.all(
              color: isEditParticipantsButtonEnabled ? Colors.teal : Colors.white,
              width: 2.5
            ),
        ),
        child: plainList,
      ),
    );
  }

  _swipeToDismissUserCallback(PublicUserProfile dismissedUserProfile) {
    _detailedChatBloc.add(UserRemovedFromChatRoom(userId: dismissedUserProfile.userId, roomId: widget.currentChatRoom.id));
  }

  _handleEditParticipantsButtonPressed() {
    if (!isEditParticipantsButtonEnabled) {
      setState(() {
        isEditParticipantsButtonEnabled = true;
      });
    }
    else {
      setState(() {
        isEditParticipantsButtonEnabled = false;
      });
    }
  }

  _renderHintIfNeeded() {
    if (widget.currentChatRoom.type == "group" && isEditParticipantsButtonEnabled) {
      return const Text(
        "Swipe left to remove participants from the chat",
        style: TextStyle(
          color: Colors.teal,
          fontSize: 14,
        ),
      );
    }
  }

  _renderEditParticipantsButtonIfNeeded() {
    if (widget.currentChatRoom.type == "group") {
      return InkWell(
        onTap: () {
          _handleEditParticipantsButtonPressed();
        },
        child: const Center(
          child: Text(
            "Edit participants",
            style: TextStyle(
              color: Colors.teal,
              fontSize: 18,
            ),
          ),
        ),
      );
    }
  }

  _renderChatPictures() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [widget.currentUserProfile, ...widget.otherUserProfiles].map((e) {
        return [
          WidgetUtils.spacer(2.5),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: ImageUtils.getUserProfileImage(e, 100, 100),
            ),
          )
        ];
      }).expand((element) => element).toList(),
    );
  }

  _renderChatTitle() {
    if (widget.otherUserProfiles.length == 1) {
      return const Center(
        child: Text(
            "Private conversation",
                style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal
          ),
        ),
      );
    }
    else {
      return IntrinsicWidth(
        child: Stack(
          // alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                child: currentChatTitleWidget,
              ),
            ),
            InkWell(
              onTap: () {
                // Make above text editable by changing `currentChatTitleWidget`
                setState(() {
                  toggleChatTitle();
                });
              },
              child: Align(
                alignment: Alignment.topRight,
                child: currentChatTitleIcon,
              ),
            ),
          ],
        ),
      );
    }
  }

  toggleChatTitle() {
    if (!isEditingChatTitle) {
      isEditingChatTitle = true;
      currentChatTitleIcon = const Icon(
        Icons.check,
        size: 20,
        color: Colors.teal,
      );
      currentChatTitleWidget = TextFormField(
        initialValue: currentChatTitleEdited,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (text) {
          currentChatTitleEdited = text;
        },
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal
        ),
      );
    }
    else {
      isEditingChatTitle = false;
      currentChatTitleIcon = const Icon(
        Icons.edit,
        size: 20,
        color: Colors.teal,
      );
      currentChatTitleWidget = Text(
        currentChatTitleEdited,
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal
        ),
      );
      // Update chat room title via bloc-API call
      _detailedChatBloc.add(ChatRoomNameChanged(newName: currentChatTitleEdited, roomId: widget.currentChatRoom.id));
    }
  }

}