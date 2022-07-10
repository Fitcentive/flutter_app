import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_post/create_new_post_view.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_bloc.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_event.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NewsFeedView extends StatefulWidget {
  final PublicUserProfile userProfile;

  const NewsFeedView({Key? key, required this.userProfile}) : super(key: key);

  static Widget withBloc(PublicUserProfile userProfile) => MultiBlocProvider(
        providers: [
          BlocProvider<NewsFeedBloc>(
              create: (context) => NewsFeedBloc(
                    socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  )),
        ],
        child: NewsFeedView(userProfile: userProfile),
      );

  @override
  State createState() {
    return NewsFeedViewState();
  }
}

class NewsFeedViewState extends State<NewsFeedView> {
  late final NewsFeedBloc _newsFeedBloc;
  late final AuthenticationBloc _authenticationBloc;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _newsFeedBloc = BlocProvider.of<NewsFeedBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    _textController.text = "Share something with your community";

    final currentAuthState = _authenticationBloc.state;
    if (currentAuthState is AuthSuccessUserUpdateState) {
      _newsFeedBloc.add(NewsFeedFetchRequested(user: currentAuthState.authenticatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsFeedBloc, NewsFeedState>(builder: (context, state) {
      return Scaffold(
        body: _newsfeedListView(state),
      );
    });
  }

  _newsfeedListView(NewsFeedState state) {
    if (state is NewsFeedDataReady) {
      if (state.posts.isNotEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            _newsFeedBloc.add(NewsFeedFetchRequested(user: state.user));
          },
          child: ListView.builder(
            itemCount: state.posts.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Column(
                  children: [
                    _addNewPostView(),
                    _separation(),
                  ],
                );
              }
              if (index >= state.posts.length + 1) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return _newsFeedListItem(state.posts[index - 1], state.userIdProfileMap);
              }
            },
          ),
        );
      }
      else {
        return const Center(
            child: Text("Awfully quiet here....")
        );
      }
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _newsFeedListItem(SocialPost post, Map<String, PublicUserProfile> userIdProfileMap) {
    final publicUser = userIdProfileMap[post.userId];
    return Container(
      padding: const EdgeInsets.all(10),
      child: Card(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: WidgetUtils.skipNulls(
                  [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: ImageUtils.getUserProfileImage(publicUser, 100, 100),
                            ),
                          ),
                        ),
                        WidgetUtils.spacer(20),
                        Text(
                          StringUtils.getUserNameFromUserId(post.userId, publicUser),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    WidgetUtils.spacer(10),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
                              child: Text(post.text),
                            )
                        )
                      ],
                    ),
                    WidgetUtils.spacer(5),
                    WidgetUtils.generatePostImageIfExists(post.photoUrl),
                    WidgetUtils.spacer(5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(2.5, 0, 0, 0),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text("${post.numberOfLikes} people like this"),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 0, 2.5, 0),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Text("${post.numberOfComments} comments"),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text(
                                      "Like",
                                    style: TextStyle(
                                      fontSize: 12
                                    ),
                                  )
                              ),
                            )
                        ),
                        Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "Comment",
                                    style: TextStyle(
                                        fontSize: 12
                                    ),
                                  )
                              ),
                            )
                        ),
                        Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "Share",
                                    style: TextStyle(
                                        fontSize: 12
                                    ),
                                  )
                              ),
                            )
                        ),
                      ],
                    ),
                  ]
              ),
            ),
          ),
      ),
    );
  }

  Widget _separation() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
              child: Container(
                height: 30,
                width: 30,
                color: Colors.teal,
              )
          )
        ],
      ),
    );
  }

  Widget _addNewPostView() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(context, UserProfileView.route(widget.userProfile), (route) => true);
            },
            child: CircleAvatar(
              radius: 30,
              child: Container(
                padding: const EdgeInsets.all(5),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(widget.userProfile, 100, 100),
                ),
              ),
            ),
          ),
          WidgetUtils.spacer(10),
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(context, CreateNewPostView.route(widget.userProfile), (route) => true);
            },
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Container(
                    padding: const EdgeInsets.all(15),
                    child: const Center(
                      child: Text("Share something with your community"),
                    ))),
          )
        ],
      ),
    );
  }
}
