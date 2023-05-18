import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/models/chats/chat_room.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_bloc.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_event.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/select_chat_users/select_chat_users_view.dart';
import 'package:flutter_app/src/views/shared_components/user_results_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedChatView extends StatefulWidget {
  static const String routeName = "chat/user/info";

  final Meetup? associatedMeetup;
  final ChatRoom currentChatRoom;
  final PublicUserProfile currentUserProfile;
  final List<PublicUserProfile> otherUserProfiles;

  static Route route({
    required Meetup? associatedMeetup,
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
              associatedMeetup: associatedMeetup,
              currentChatRoom: currentChatRoom,
              otherUserProfiles: otherUserProfiles,
              currentUserProfile: currentUserProfile
          ),
        )
    );
  }

  const DetailedChatView({
    Key? key,
    required this.associatedMeetup,
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
  List<PublicUserProfile> chatParticipantUserProfiles = [];

  @override
  void initState() {
    super.initState();

    chatParticipantUserProfiles = [widget.currentUserProfile, ...widget.otherUserProfiles];
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
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      floatingActionButton: Visibility(
          visible: isEditParticipantsButtonEnabled,
          child: _addParticipantsToChatButton()
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
        title: const Text('Chat Info', style: TextStyle(color: Colors.teal),),
      ),
      body: WillPopScope(
        onWillPop: () async {
          await _updateChatParticipantsViaApiCall();
          return true;
        },
        child: Scrollbar(
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
              _renderChatParticipants(),
              WidgetUtils.spacer(5),
              _renderLeaveChatButtonIfNeeded(),
            ]),
          ),
        ),
      ),
    );
  }

  _updateChatParticipantsViaApiCall() {
    final List<PublicUserProfile> otherParticipants = List.from(chatParticipantUserProfiles)
      ..removeWhere((element) => element.userId == widget.currentUserProfile.userId);
    final List<PublicUserProfile> removedParticipants = widget.otherUserProfiles.toSet().difference(otherParticipants.toSet()).toList();
    final List<PublicUserProfile> addedParticipants = otherParticipants.toSet().difference(widget.otherUserProfiles.toSet()).toList();
    _detailedChatBloc.add(
        UsersAddedToChatRoom(
            userIds: addedParticipants.map((e) => e.userId).toList(),
            roomId: widget.currentChatRoom.id)
    );
    _detailedChatBloc.add(
        UsersRemovedFromChatRoom(
            userIds: removedParticipants.map((e) => e.userId).toList(),
            roomId: widget.currentChatRoom.id)
    );
  }

  _leaveChatAndGoToChatHomeView() {
    Widget cancelButton = TextButton(
      child: const Text("Cancel", style: TextStyle(color: Colors.teal),),
      onPressed:  () {
        Navigator.pop(context, false);
      },
    );

    Widget confirmButton = TextButton(
      child: const Text("Confirm", style: TextStyle(color: Colors.teal)),
      onPressed:  () {
        // Add callback here
        _detailedChatBloc.add(
            UsersRemovedFromChatRoom(
                userIds: [widget.currentUserProfile.userId],
                roomId: widget.currentChatRoom.id
            )
        );
        Navigator.pushReplacement(context, HomePage.route(defaultSelectedTab: HomePageState.chat));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Leave this chat?"),
      content: const Text("Are you sure? This cannot be undone"),
      actions: [
        cancelButton,
        confirmButton,
      ],
    );

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );


  }

  _renderLeaveChatButtonIfNeeded() {
    if (widget.currentChatRoom.type == "group") {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton.icon(
            icon: const Icon(
              Icons.exit_to_app
            ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
            ),
            onPressed: () async {
              // Leave chat room and pop screens if possible
              if (chatParticipantUserProfiles.length <= 3) {
                SnackbarUtils.showSnackBar(context, "Cannot leave chat, a minimum of 3 users is required in a group chat!");
              }
              else {
                _leaveChatAndGoToChatHomeView();
              }
            },
            label: const Text("Leave Chat", style: TextStyle(fontSize: 15, color: Colors.white)),
          ),
        ),
      );
    }
  }

  _addParticipantsToChatButton() {
    return FloatingActionButton(
      heroTag: "DetailedChatViewAddParticipantToChatButton",
      onPressed: () {
        Navigator.push<List<PublicUserProfile>>(
            context,
            SelectChatUsersView.route(
                currentChatRoom: widget.currentChatRoom,
                currentUserProfile: widget.currentUserProfile,
                otherUserProfiles: List.from(chatParticipantUserProfiles)
                    ..removeWhere((element) => element.userId == widget.currentUserProfile.userId)
            )
        ).then((value) {
          setState(() {
            chatParticipantUserProfiles = value ?? chatParticipantUserProfiles;
          });
        });
      },
      tooltip: 'Add participants to conversation!',
      backgroundColor: Colors.teal,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }


  _renderChatParticipants() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
            border: Border.all(
              color: isEditParticipantsButtonEnabled ? Colors.teal : Colors.transparent,
              width: 2.5
            ),
        ),
        child: UserResultsList(
          userProfiles: chatParticipantUserProfiles,
          currentUserProfile: widget.currentUserProfile,
          doesNextPageExist: false,
          fetchMoreResultsCallback:  () {},
          shouldListBeSwipable: isEditParticipantsButtonEnabled,
          swipeToDismissUserCallback: _swipeToDismissUserCallback,
        ),
      ),
    );
  }

  _swipeToDismissUserCallback(PublicUserProfile dismissedUserProfile) {
    // Only save state on WillPopScope
    // _detailedChatBloc.add(UsersRemovedFromChatRoom(userIds: [dismissedUserProfile.userId], roomId: widget.currentChatRoom.id));
    setState(() {
      chatParticipantUserProfiles = List.from(chatParticipantUserProfiles)
        ..removeWhere((element) => element.userId == dismissedUserProfile.userId);
    });
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
    if (widget.currentChatRoom.type == "group" && widget.associatedMeetup == null) {
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
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: chatParticipantUserProfiles.map((e) {
          return [
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
      ),
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
      _detailedChatBloc.add(ChatRoomNameChanged(newName: currentChatTitleEdited, roomIds: widget.currentChatRoom.id));
    }
  }

}