import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';

typedef FetchMoreResultsCallback = void Function();
typedef GoToChatRoomCallBack = void Function(PublicUserProfile targetUserProfile);
typedef SwipeToDismissUserCallback = void Function(PublicUserProfile targetUserProfile);

class UserResultsList extends StatefulWidget {

  final List<PublicUserProfile> userProfiles;
  final PublicUserProfile currentUserProfile;
  final bool doesNextPageExist;
  final bool shouldTapGoToChatRoom;
  final bool shouldListBeSwipable;

  final FetchMoreResultsCallback fetchMoreResultsCallback;
  final GoToChatRoomCallBack? goToChatRoomCallBack;
  final SwipeToDismissUserCallback? swipeToDismissUserCallback;

  const UserResultsList({
    Key? key,
    this.shouldListBeSwipable = false,
    this.shouldTapGoToChatRoom = false,
    this.goToChatRoomCallBack,
    required this.userProfiles,
    required this.currentUserProfile,
    required this.doesNextPageExist,
    required this.fetchMoreResultsCallback,
    required this.swipeToDismissUserCallback,
  }): super(key: key);

  @override
  State createState() {
    return UserResultsListState();
  }
}

class UserResultsListState extends State<UserResultsList> {
  static const double _scrollThreshold = 200.0;

  final _scrollController = ScrollController();
  bool isDataBeingRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text(widget.userProfiles.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(child: _searchResults(widget.userProfiles))
      ],
    );
  }

  Widget _searchResults(List<PublicUserProfile> items) {
    isDataBeingRequested = false;
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: widget.doesNextPageExist ? items.length + 1 : items.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _userSearchResultItem(items[index]);
          }
        },
      ),
    );
  }

  Widget _userSearchResultItem(PublicUserProfile userProfile) {
    final plainTile = ListTile(
      title: Text("${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Text(""),
      subtitle: Text(userProfile.username ?? ""),
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(userProfile, 500, 500),
          ),
        ),
      ),
      onTap: () {
        if (widget.shouldTapGoToChatRoom) {
          widget.goToChatRoomCallBack!(userProfile);
        }
        else {
          Navigator.pushAndRemoveUntil(
              context,
              UserProfileView.route(userProfile, widget.currentUserProfile),
                  (route) => true
          );
        }
      },
    );

    if (widget.shouldListBeSwipable) {
      return Dismissible(
          key: Key(userProfile.userId),
          background: Container(
            color: Colors.teal,
          ),
          confirmDismiss: (direction) {
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
                Navigator.pop(context, true);
              },
            );

            // set up the AlertDialog
            AlertDialog alert = AlertDialog(
              title: const Text("Remove user from chat?"),
              content: const Text("Are you sure? This cannot be undone"),
              actions: [
                cancelButton,
                confirmButton,
              ],
            );


            if (widget.currentUserProfile.userId == userProfile.userId) {
              return Future.value(false);
            }
            else {
              // show the dialog
              return showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return alert;
                },
              );
            }

          },
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _removeUserFromConversation(userProfile);
            }
          },
          child: plainTile
      );
    }
    else {
      return plainTile;
    }
  }

  // todo - there is an error here, need to fix
  // todo - add UI for adding new user to chat - similar to adding users to meetup!?
  _removeUserFromConversation(PublicUserProfile userProfile) {
    if (widget.shouldListBeSwipable) {
      if (userProfile.userId != widget.currentUserProfile.userId) {
        widget.swipeToDismissUserCallback!(userProfile);
      }
    }
  }

  void _onScroll() {
    if(_scrollController.hasClients ) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        isDataBeingRequested = true;
        widget.fetchMoreResultsCallback();
      }
    }
  }

}