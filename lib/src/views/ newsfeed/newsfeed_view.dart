import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/%20newsfeed/bloc/newsfeed_bloc.dart';
import 'package:flutter_app/src/views/%20newsfeed/bloc/newsfeed_event.dart';
import 'package:flutter_app/src/views/%20newsfeed/bloc/newsfeed_state.dart';
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
        body: Column(
          children: [
            _addNewPostView(),
            _separation(),
            _newsfeedListView(state),
          ],
        ),
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
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.posts.length,
            itemBuilder: (BuildContext context, int index) {
              if (index >= state.posts.length) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return _newsFeedListItem(state.posts[index]);
              }
            },
          ),
        );
      }
      else {
        return const Expanded(
            child: Center(
                child: Text("Awfully quiet here....")
            )
        );
      }
    } else {
      return const Expanded(
          child: Center(
            child: CircularProgressIndicator(),
          )
      );
    }
  }

  Widget _newsFeedListItem(SocialPost post) {
    return Expanded(
        child: Card(
          child: SizedBox(
            height: 100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: CircleAvatar(
                      radius: 30,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: ImageUtils.getImage(post.photoUrl, 100, 100),
                        ),
                      ),
                    )),
                    Expanded(child: Text(post.userId))
                  ],
                ),
                Row(
                  children: [Expanded(child: Text(post.text))],
                ),
                Row(
                  children: [
                    Expanded(
                        child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        image: ImageUtils.getImage(post.photoUrl, 100, 100),
                      ),
                    ))
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("${post.numberOfLikes} people like this")),
                    Expanded(child: Text("${post.numberOfComments} comments")),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: () {}, child: Text("Like"))),
                    Expanded(child: ElevatedButton(onPressed: () {}, child: Text("Comment"))),
                    Expanded(child: ElevatedButton(onPressed: () {}, child: Text("Share"))),
                  ],
                ),
          ],
        ),
      ),
    ));
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
          ))
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
              // Open create post view
            },
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Container(
                    padding: EdgeInsets.all(15),
                    child: const Center(
                      child: Text("Share something with your community"),
                    ))),
          )
        ],
      ),
    );
  }
}
