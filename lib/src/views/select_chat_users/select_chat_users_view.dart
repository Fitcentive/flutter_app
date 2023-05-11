import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/models/chats/chat_room.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/select_chat_users/bloc/select_chat_users_bloc.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectChatUsersView extends StatefulWidget {
  static const String routeName = "/chat/select-users";
  final ChatRoom currentChatRoom;
  final PublicUserProfile currentUserProfile;
  final List<PublicUserProfile> otherUserProfiles;

  static Route<List<PublicUserProfile>> route({
    required ChatRoom currentChatRoom,
    required PublicUserProfile currentUserProfile,
    required List<PublicUserProfile> otherUserProfiles,
  }) {
    return MaterialPageRoute<List<PublicUserProfile>>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<SelectChatUsersBloc>(
                create: (context) => SelectChatUsersBloc(
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                )),
          ],
          child: SelectChatUsersView(
              currentChatRoom: currentChatRoom,
              otherUserProfiles: otherUserProfiles,
              currentUserProfile: currentUserProfile
          ),
        )
    );
  }

  const SelectChatUsersView({
    Key? key,
    required this.currentChatRoom,
    required this.currentUserProfile,
    required this.otherUserProfiles
  }): super(key: key);


  @override
  State createState() {
    return SelectChatUsersViewState();
  }
}

class SelectChatUsersViewState extends State<SelectChatUsersView> {

  List<PublicUserProfile> chatParticipantUserProfiles = [];

  @override
  void initState() {
    super.initState();

    chatParticipantUserProfiles = [widget.currentUserProfile, ...widget.otherUserProfiles];
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: adWidget,
      appBar: AppBar(
        title: const Text("Select chat users", style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, chatParticipantUserProfiles);
          return false;
        },
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WidgetUtils.spacer(2.5),
                _renderParticipantsView(),
                WidgetUtils.spacer(2.5),
                Divider(color: Theme.of(context).primaryColor),
                WidgetUtils.spacer(2.5),
                _renderSearchUserSelectView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onParticipantRemoved(PublicUserProfile removedUser) {
    if (removedUser.userId == widget.currentUserProfile.userId) {
      SnackbarUtils.showSnackBar(context, "Cannot remove yourself! Use the leave chat button instead.");
    }
    else if (chatParticipantUserProfiles.length <= 3) {
      SnackbarUtils.showSnackBar(context, "A minimum of 3 users is required in a group chat!");
      selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemSelected(removedUser.userId);
    }
    else {
      setState(() {
        chatParticipantUserProfiles = List.from(chatParticipantUserProfiles)
          ..removeWhere((element) => element.userId == removedUser.userId);
      });
      selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(removedUser.userId);
    }
  }

  _addSelectedUserIdToParticipantsCallback(PublicUserProfile selectedUserProfile) {
    setState(() {
      chatParticipantUserProfiles = List.from(chatParticipantUserProfiles)
        ..add(selectedUserProfile);
    });
  }

  _renderSearchUserSelectView() {
    return SelectFromUsersView.withBloc(
      key: selectFromFriendsViewStateGlobalKey,
      currentUserId: widget.currentUserProfile.userId,
      currentUserProfile: widget.currentUserProfile,
      addSelectedUserIdToParticipantsCallback: _addSelectedUserIdToParticipantsCallback,
      removeSelectedUserFromToParticipantsCallback: _onParticipantRemoved,
      alreadySelectedUserProfiles: widget.otherUserProfiles,
      isRestrictedOnlyToFriends: false,
    );
  }

  _renderParticipantsView() {
    if (chatParticipantUserProfiles.isNotEmpty) {
      return ParticipantsList(
        participantUserProfiles: chatParticipantUserProfiles,
        onParticipantRemoved: _onParticipantRemoved,
        onParticipantTapped: null,
        participantDecisions: const [],
        shouldShowAvailabilityIcon: false,
      );
    }
    else {
      return Container(
        constraints: const BoxConstraints(
          minHeight: 60,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Center(
                child: Text("Add users to chat..."),
              )
            ],
          ),
        ),
      );
    }
  }

}