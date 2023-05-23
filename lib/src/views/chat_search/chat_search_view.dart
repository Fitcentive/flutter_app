import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_bloc.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_event.dart';
import 'package:flutter_app/src/views/chat_search/bloc/chat_search_state.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ChatSearchView extends StatefulWidget {
  static const String routeName = "chat/user/search";

  final PublicUserProfile currentUserProfile;

  const ChatSearchView({Key? key, required this.currentUserProfile}): super(key: key);

  static Route route(PublicUserProfile currentUserProfile) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<ChatSearchBloc>(
                create: (context) => ChatSearchBloc(
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                  userRepository: RepositoryProvider.of<UserRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: ChatSearchView(currentUserProfile: currentUserProfile),
        )
    );
  }


  @override
  State createState() {
    return ChatSearchViewState();
  }

}

class ChatSearchViewState extends State<ChatSearchView> {
  bool isPremiumEnabled = false;
  int maxOtherChatParticipants = ConstantUtils.MAX_OTHER_CHAT_PARTICIPANTS_FREE;
  late final ChatSearchBloc _chatSearchBloc;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  List<String> selectedParticipants = List<String>.empty(growable: true);
  List<PublicUserProfile> selectedMeetupParticipantProfiles = [];

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchTextController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _chatSearchBloc = BlocProvider.of<ChatSearchBloc>(context);
    _chatSearchBloc.add(ChatParticipantsChanged(
      currentUserProfile: widget.currentUserProfile,
      participantUserIds: const [],
    ));

    isPremiumEnabled = WidgetUtils.isPremiumEnabledForUser(context);
    if (isPremiumEnabled) {
      maxOtherChatParticipants = ConstantUtils.MAX_OTHER_CHAT_PARTICIPANTS_PREMIUM;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      floatingActionButton: FloatingActionButton(
        heroTag: "GoToChatRoomButton",
        onPressed: _goToChatRoomCallback,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.chat, color: Colors.white)
      ),
      appBar: AppBar(
        title: const Text("New message", style: TextStyle(color: Colors.teal)),
        iconTheme: const IconThemeData(color: Colors.teal),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.chat,
              color: Colors.teal,
            ),
            tooltip: "Start conversation",
            onPressed: () {
              _goToChatRoomCallback();
            },
          )
        ],
      ),
      body: BlocListener<ChatSearchBloc, ChatSearchState>(
        listener: (context, state) {
          if (state is ChatParticipantsModified) {
            setState(() {
              selectedMeetupParticipantProfiles  = List.from(state.participantUserProfiles);
            });
          }
          else if (state is GoToUserChatView) {
            _openUserChatView(state.roomId, state.targetUserProfiles);
          }
          else if (state is TargetUserChatNotEnabled) {
            SnackbarUtils.showSnackBar(context, "This user has not enabled chat yet!");
          }
        },
        child: BlocBuilder<ChatSearchBloc, ChatSearchState>(
          builder: (context, state) {
            if (state is ChatParticipantsModified) {
              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _renderParticipantsView(state),
                      WidgetUtils.spacer(2.5),
                      Divider(color: Theme.of(context).primaryColor),
                      WidgetUtils.spacer(2.5),
                      _renderSearchUserSelectView(state),
                    ],
                  ),
                ),
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
    );
  }

  _removeSelectedUserFromToParticipantsCallback(PublicUserProfile removedUserProfile) {
    final newParticipants = [...selectedParticipants];
    newParticipants.removeWhere((element) => element == removedUserProfile.userId);
    _updateBlocState(newParticipants);
    setState(() {
      selectedMeetupParticipantProfiles.removeWhere((element) => element.userId == removedUserProfile.userId);
    });
  }

  _goToAccountDetailsView() {
    Navigator.pushReplacement(
        context,
        HomePage.route(defaultSelectedTab: HomePageState.accountDetails),
    );
  }

  _addSelectedUserIdToParticipantsCallback(PublicUserProfile selectedUserProfile) {
    if (selectedParticipants.length >= maxOtherChatParticipants) {
      if (maxOtherChatParticipants == ConstantUtils.MAX_OTHER_CHAT_PARTICIPANTS_PREMIUM) {
        SnackbarUtils.showSnackBarShort(context, "Cannot add more than $maxOtherChatParticipants users to a conversation!");
      }
      else {
        WidgetUtils.showUpgradeToPremiumDialog(context, _goToAccountDetailsView);
        SnackbarUtils.showSnackBarShort(context, "Upgrade to premium for group chats!");
      }
      selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(selectedUserProfile.userId);
    }
    else {
      _updateBlocState({...selectedParticipants, selectedUserProfile.userId}.toList());
    }
  }

  _renderSearchUserSelectView(ChatParticipantsModified state) {
    return SelectFromUsersView.withBloc(
      key: selectFromFriendsViewStateGlobalKey,
      currentUserId: widget.currentUserProfile.userId,
      currentUserProfile: widget.currentUserProfile,
      addSelectedUserIdToParticipantsCallback: _addSelectedUserIdToParticipantsCallback,
      removeSelectedUserFromToParticipantsCallback: _removeSelectedUserFromToParticipantsCallback,
      alreadySelectedUserProfiles: [],
      isRestrictedOnlyToFriends: false,
    );
  }

  _updateUserSearchResultsListIfNeeded(String userId) {
    selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(userId);
  }

  _updateBlocState(List<String> participantUserIds) {
    final currentState = _chatSearchBloc.state;
    if (currentState is ChatParticipantsModified) {
      _chatSearchBloc.add(
          ChatParticipantsChanged(
              currentUserProfile: currentState.currentUserProfile,
              participantUserIds: participantUserIds,
          )
      );
      setState(() {
        selectedParticipants = participantUserIds;
      });
    }
  }

  _onParticipantRemoved(PublicUserProfile removedUser) {
    final updatedListAfterRemovingParticipant = [...selectedParticipants];
    updatedListAfterRemovingParticipant.removeWhere((element) => element == removedUser.userId);
    _updateBlocState(updatedListAfterRemovingParticipant);
    _updateUserSearchResultsListIfNeeded(removedUser.userId);

    setState(() {
      selectedMeetupParticipantProfiles.removeWhere((element) => element.userId == removedUser.userId);
    });
  }

  _renderParticipantsView(ChatParticipantsModified state) {
    if (selectedMeetupParticipantProfiles.isNotEmpty) {
      return ParticipantsList(
        participantUserProfiles: selectedMeetupParticipantProfiles,
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
                child: Text("Add users to a conversation..."),
              )
            ],
          ),
        ),
      );
    }
  }

  _goToChatRoomCallback() {
    if (selectedMeetupParticipantProfiles.isEmpty) {
      SnackbarUtils.showSnackBarShort(context, "Please select at least one user to chat with!");
    }
    else {
      _chatSearchBloc.add(GetChatRoom(targetUserProfiles: selectedMeetupParticipantProfiles));
    }
  }

  _openUserChatView(String roomId, List<PublicUserProfile> targetUserProfiles) {
    if (targetUserProfiles.length == 1) {
      Navigator.pushReplacement(
          context,
          UserChatView.route(
              currentRoomId: roomId,
              currentUserProfile: widget.currentUserProfile,
              otherUserProfiles: [targetUserProfiles.single]
          ),
      );
    }
    else {
      Navigator.pushReplacement(
          context,
          UserChatView.route(
              currentRoomId: roomId,
              currentUserProfile: widget.currentUserProfile,
              otherUserProfiles: targetUserProfiles
          ),
      );
    }
  }

}