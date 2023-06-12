import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';

typedef FetchMoreResultsCallback = void Function();
typedef GoToChatRoomCallBack = void Function(PublicUserProfile targetUserProfile);
typedef SwipeToDismissUserCallback = void Function(PublicUserProfile targetUserProfile);
typedef ModifyUserAdminStatusCallback = void Function(PublicUserProfile targetUserProfile);

class UserResultsList extends StatefulWidget {

  final List<PublicUserProfile> userProfiles;
  final PublicUserProfile currentUserProfile;
  final bool doesNextPageExist;
  final bool shouldTapGoToChatRoom;
  final bool shouldListBeSwipable;

  final FetchMoreResultsCallback fetchMoreResultsCallback;
  final GoToChatRoomCallBack? goToChatRoomCallBack;
  final SwipeToDismissUserCallback? swipeToDismissUserCallback;

  // Every userId that is in this list will get an admin badge suffixed into the ListTile
  // Only used from chat participants list, nowehere else
  final List<String> adminUserIds;
  final bool isLongPressToMakeUserAdminEnabled;
  final ModifyUserAdminStatusCallback ? makeUserAnAdminCallback;
  final ModifyUserAdminStatusCallback ? removeAdminStatusForUserCallback;

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
    this.adminUserIds = const [],
    this.isLongPressToMakeUserAdminEnabled = false,
    this.makeUserAnAdminCallback,
    this.removeAdminStatusForUserCallback,
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

  _createAdminBadge() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal,
          border: Border.all(
            color: Colors.teal,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10))
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          "Admin",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  _showConfirmationToMakeUserAnAdmin(PublicUserProfile userProfile) {
    _dialogContent() {
      return Column(
        children: [
          WidgetUtils.spacer(5),
          const Text(
            "Admin confirmation",
            style: TextStyle(
                fontSize: 20,
                color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(10),
          Text(
            "You are about to make ${StringUtils.getUserNameFromUserProfile(userProfile)} an admin of this chat room. Are you sure?",
            style: const TextStyle(
              fontSize: 16,
              // color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
              const Expanded(
                  flex: 1,
                  child: Visibility(
                    visible: false,
                    child: Text(""),
                  )
              ),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (widget.makeUserAnAdminCallback != null) {
                      widget.makeUserAnAdminCallback!(userProfile);
                    }
                  },
                  child: const Text(
                      "Continue",
                      style: TextStyle(fontSize: 15, color: Colors.white)
                  ),
                ),
              ),
            ],
          )
        ],
      );
    }

    _dialogContentCard() {
      return IntrinsicHeight(
        child: Card(
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: _dialogContent(),
              ),
            )
        ),
      );
    }

    showDialog(context: context, builder: (context) {
      return Dialog(
        child: _dialogContentCard(),
      );
    });
  }

  _showConfirmationToRemoveUserAsAdmin(PublicUserProfile userProfile) {
    _dialogContent() {
      return Column(
        children: [
          WidgetUtils.spacer(5),
          const Text(
            "Admin confirmation",
            style: TextStyle(
                fontSize: 20,
                color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(10),
          Text(
            userProfile.userId == widget.currentUserProfile.userId ?
            "You are about to remove yourself as an admin of this chat room. Are you sure?" :
            "You are about to remove ${StringUtils.getUserNameFromUserProfile(userProfile)} as an admin of this chat room. Are you sure?",
            style: const TextStyle(
              fontSize: 16,
              // color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
              const Expanded(
                  flex: 1,
                  child: Visibility(
                    visible: false,
                    child: Text(""),
                  )
              ),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (widget.removeAdminStatusForUserCallback != null) {
                      widget.removeAdminStatusForUserCallback!(userProfile);
                    }
                  },
                  child: const Text(
                      "Remove",
                      style: TextStyle(fontSize: 15, color: Colors.white)
                  ),
                ),
              ),
            ],
          )
        ],
      );
    }

    _dialogContentCard() {
      return IntrinsicHeight(
        child: Card(
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: _dialogContent(),
              ),
            )
        ),
      );
    }

    showDialog(context: context, builder: (context) {
      return Dialog(
        child: _dialogContentCard(),
      );
    });
  }

  Widget _userSearchResultItem(PublicUserProfile userProfile) {
    final plainTile = ListTile(
      title: Text("${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: widget.adminUserIds.contains(userProfile.userId) ? _createAdminBadge() : const Text(""),
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
      onLongPress: () {
        if (widget.isLongPressToMakeUserAdminEnabled && widget.adminUserIds.contains(widget.currentUserProfile.userId)) {
          // Show menu here with options only if user current user is an admin
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text(
                      "Participant options",
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 16,
                    ),
                  ),
                  content: SizedBox(
                    height: 100.0,
                    width: 100.0,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 2,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              if (widget.adminUserIds.contains(userProfile.userId)) {
                                SnackbarUtils.showSnackBarMedium(context, "User is already an admin!");
                              }
                              else {
                                _showConfirmationToMakeUserAnAdmin(userProfile);
                              }
                            },
                            title: const Text('Add as admin'),
                          );
                        }
                        else {
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              if (widget.adminUserIds.length >= 2) {
                                _showConfirmationToRemoveUserAsAdmin(userProfile);
                              }
                              else {
                                SnackbarUtils.showSnackBarMedium(context, "Cannot remove any more admins!");
                              }
                            },
                            title: const Text('Remove as admin'),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
          );
        }
      },
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
          background: WidgetUtils.viewUnderDismissibleListTile(),
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
              SnackbarUtils.showSnackBar(context, "Cannot remove yourself! Please use the leave chat button instead.");
              return Future.value(false);
            }
            else if (widget.userProfiles.length <= 3) {
              SnackbarUtils.showSnackBar(context, "A minimum of 3 users is required in a group chat!");
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