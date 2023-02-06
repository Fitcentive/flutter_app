import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup_comment.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_bloc.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_event.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class MeetupCommentsListView extends StatefulWidget {
  final String currentUserId;
  final String meetupId;

  const MeetupCommentsListView({Key? key, required this.meetupId, required this.currentUserId}): super(key: key);

  static Widget withBloc({required String meetupId, Key? key, required String currentUserId}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MeetupCommentsListBloc>(
            create: (context) => MeetupCommentsListBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: MeetupCommentsListView(meetupId: meetupId, key: key, currentUserId: currentUserId),
    );
  }

  @override
  State createState() {
    return MeetupCommentsListViewState();
  }
}

// This is currently not being used
class MeetupCommentsListViewState extends State<MeetupCommentsListView> {

  late final MeetupCommentsListBloc _meetupCommentsListBloc;
  late final AuthenticationBloc _authenticationBloc;

  final TextEditingController _textEditingController = TextEditingController();
  List<MeetupComment> fetchedComments = List.empty();

  String? newUserComment;

  @override
  void dispose() {
    _textEditingController.dispose();
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
            currentUserId: widget.currentUserId
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetupCommentsListBloc, MeetupCommentsListState>(
      builder: (context, state) {
        if (state is MeetupCommentsLoaded) {
          fetchedComments = state.comments;
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // _commentsListView(state.userIdProfileMap),
              LimitedBox(
                maxHeight: 300,
                // constraints: const BoxConstraints(maxHeight: 350),
                child: _commentsListView(state.userIdProfileMap),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 50, maxHeight: 75),
                  child: _createAddCommentView(),
                ),
              )
            ],
          );
        }
        else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

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
                    hintText: "Write a comment..."
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
            onTap: () {
              showDialog(context: context, builder: (context) {
                return _addCommentDialog();
              });
            },
            child: FittedBox(
              fit:BoxFit.fitHeight,
              child:  Container(
                  width: ScreenUtils.getScreenWidth(context) * 0.75,
                  padding: const EdgeInsets.all(15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      newUserComment ?? "Write a comment...",
                    ),
                  )
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
    }
  }

  _commentsListView(Map<String, PublicUserProfile> userProfiles) {
    if (fetchedComments.isEmpty) {
      return GestureDetector(
        onTap: () {
          KeyboardUtils.hideKeyboard(context);
        },
        child: const Center(
            child: Text("Awfully quiet here....")
        ),
      );
    }
    else {
      return RefreshIndicator(
        onRefresh: () async {
          _meetupCommentsListBloc.add(FetchMeetupCommentsRequested(
              meetupId: widget.meetupId!,
              currentUserId: widget.currentUserId
          ));
        },
        child: GestureDetector(
          onTap: () {
            KeyboardUtils.hideKeyboard(context);
          },
          child: Scrollbar(
              child: ListView.builder(
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
                DateFormat(ConstantUtils.timestampFormat).format(comment.createdAt.add(DateTime.now().timeZoneOffset)),
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