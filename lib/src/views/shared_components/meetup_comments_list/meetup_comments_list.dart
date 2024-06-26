import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup_comment.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_bloc.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_event.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skeleton_loader/skeleton_loader.dart';
import 'package:timeago/timeago.dart' as timeago;

class MeetupCommentsListView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final String meetupId;

  const MeetupCommentsListView({Key? key, required this.meetupId, required this.currentUserProfile}): super(key: key);

  static Widget withBloc({required String meetupId, Key? key, required PublicUserProfile currentUserProfile}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MeetupCommentsListBloc>(
            create: (context) => MeetupCommentsListBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: MeetupCommentsListView(meetupId: meetupId, key: key, currentUserProfile: currentUserProfile),
    );
  }

  @override
  State createState() {
    return MeetupCommentsListViewState();
  }
}

class MeetupCommentsListViewState extends State<MeetupCommentsListView> {

  late final MeetupCommentsListBloc _meetupCommentsListBloc;
  late final AuthenticationBloc _authenticationBloc;

  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MeetupComment> fetchedComments = List.empty();

  final focusNode = FocusNode();

  String? newUserComment;

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _meetupCommentsListBloc = BlocProvider.of<MeetupCommentsListBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    _meetupCommentsListBloc.add(
        FetchMeetupCommentsRequested(
            meetupId: widget.meetupId,
            currentUserId: widget.currentUserProfile.userId
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetupCommentsListBloc, MeetupCommentsListState>(
      builder: (context, state) {
        if (state is MeetupCommentsLoaded) {
          fetchedComments = state.comments;
          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 400
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _commentsListView(state.userIdProfileMap),
                Flexible(
                  child: LimitedBox(
                    maxHeight: 300,
                    // constraints: const BoxConstraints(maxHeight: 350),
                    child: _commentsListView(state.userIdProfileMap),
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 50, maxHeight: 75),
                    child: _createAddCommentView(),
                  ),
                )
              ],
            ),
          );
        }
        else {
          if (DeviceUtils.isAppRunningOnMobileBrowser()) {
            return WidgetUtils.progressIndicator();
          }
          else {
            return _renderLoadingSkeleton();
          }
        }
      },
    );
  }

  _renderLoadingSkeleton() {
    return SingleChildScrollView(
      child: SkeletonLoader(
        builder: ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            return _stubItem();
          },
        ),
      ),
    );
  }

  _stubItem() {
    return ListTile(
      title: Container(
        width: ScreenUtils.getScreenWidth(context),
        height: 10,
        color: Colors.white,
      ),
      subtitle:  Container(
        width: 25,
        height: 10,
        color: Colors.white,
      ),
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 500, 500),
          ),
        ),
      ),
    );
  }

  // Unused, legacy code
  _addCommentDialog() {
    return GestureDetector(
      onTap: () {
        KeyboardUtils.hideKeyboard(context);
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text("Add Comment", style: TextStyle(color: Colors.teal),),
              iconTheme: const IconThemeData(
                color: Colors.teal,
              ),
            ),
            body: Align(
              alignment: Alignment.bottomLeft,
              child: TextField(
                textCapitalization: TextCapitalization.sentences,
                onChanged: (text) {
                  setState(() {
                    if (text.trim().isNotEmpty) {
                      newUserComment = text;
                    }
                    else {
                      newUserComment = null;
                    }
                  });
                },
                decoration: const InputDecoration(
                    hintText: "Write a comment...",
                    hintStyle: const TextStyle(color: Colors.grey),
                ),
                controller: _textEditingController,
                expands: true,
                minLines: null,
                maxLines: null,
              ),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              ElevatedButton(
                  onPressed: () {
                    if (_textEditingController.value.text.trim().isEmpty) {
                      newUserComment = null;
                      _textEditingController.text = "";
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel")
              ),
              const Spacer(),
              ElevatedButton(
                  onPressed: () {
                    _onSubmitButtonPressed();
                    Navigator.pop(context);
                  },
                  child: const Text("Post")
              )
            ],
          )
        ],
      ),
    );
  }

  _createAddCommentView() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            focusColor: Colors.transparent,
            onTap: () {
              FocusScope.of(context).requestFocus(focusNode);
            },
            child: FittedBox(
              fit:BoxFit.fitHeight,
              child:  Container(
                  width: min(ScreenUtils.getScreenWidth(context) * 0.75, ConstantUtils.WEB_APP_MAX_WIDTH * 0.85),
                  padding: const EdgeInsets.all(15),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 7.5, 0, 7.5),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: TextField(
                        focusNode: focusNode,
                        controller: _textEditingController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          setState(() {
                            if (text.trim().isNotEmpty) {
                              newUserComment = text;
                            }
                            else {
                              newUserComment = null;
                            }
                          });
                        },
                        maxLines: null,
                        decoration: const InputDecoration.collapsed(
                            hintText: 'Share your thoughts here...',
                            hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

              ),
            ),
          ),

          Container(
              padding: const EdgeInsets.all(15),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: () {
                      _onSubmitButtonPressed();
                    },
                    icon: Icon(
                      Icons.send,
                      color: newUserComment == null ? Colors.grey : Colors.teal,
                    )
                ),
              )
          )
        ],
      ),
    );
  }

  _onSubmitButtonPressed() {
    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState && newUserComment != null && newUserComment!.isNotEmpty) {
      _meetupCommentsListBloc.add(
          AddNewMeetupComment(
              meetupId: widget.meetupId!,
              userId: currentAuthState.authenticatedUser.user.id,
              comment: newUserComment!
          )
      );
      _textEditingController.text = "";
      setState(() {
        newUserComment = null;
      });

      if(_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 75,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
        );
      }
    }
  }

  _commentsListView(Map<String, PublicUserProfile> userProfiles) {
    if (fetchedComments.isEmpty) {
      return GestureDetector(
        onTap: () {
          KeyboardUtils.hideKeyboard(context);
        },
        child: const SizedBox(
          height: 200,
          child: Center(
            child: Text("No activity yet... get started by adding a comment!"),
          ),
        ),
      );
    }
    else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: GestureDetector(
          onTap: () {
            KeyboardUtils.hideKeyboard(context);
          },
          child: Scrollbar(
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: fetchedComments.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index >= fetchedComments.length) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    final currentComment = fetchedComments[index];
                    final userProfile = userProfiles[currentComment.userId];
                    return _commentListItem(currentComment, userProfile);
                  }
                },
              )
          ),
        ),
      );
    }
  }

  _commentListItem(MeetupComment comment, PublicUserProfile? userProfile) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(userProfile, 100, 100),
          ),
        ),
      ),
      title: Text(
        StringUtils.getUserNameFromUserProfile(userProfile),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _userCommentText(comment),
    );
  }

  _userCommentText(MeetupComment comment) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child:  Column(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              comment.comment,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              child: Text(
                timeago.format(comment.createdAt.toLocal()),
                style: const TextStyle(
                    fontSize: 10
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

}