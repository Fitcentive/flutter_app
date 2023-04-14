import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/chats/chat_room.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_bloc.dart';
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

  @override
  void initState() {
    super.initState();

    _detailedChatBloc = BlocProvider.of<DetailedChatBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
        title: const Text('Chat Info', style: TextStyle(color: Colors.teal),),
      ),
      body: Scrollbar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WidgetUtils.spacer(5),
            _renderChatTitle(),
            WidgetUtils.spacer(10),
            _renderChatPictures(),
            WidgetUtils.spacer(10),
            _renderAddButton(),
            WidgetUtils.spacer(10),
            const Padding(
              padding: EdgeInsets.fromLTRB(17.5, 0, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Participants",
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            WidgetUtils.spacer(2.5),
            _renderChatParticipants(),
          ],
        ),
      ),
    );
  }

  _renderChatParticipants() {
    return Expanded(
      child: UserResultsList(
        userProfiles: [widget.currentUserProfile, ...widget.otherUserProfiles],
        currentUserProfile: widget.currentUserProfile,
        doesNextPageExist: false,
        fetchMoreResultsCallback:  () {},
      ),
    );
  }

  _renderAddButton() {
    return Center(
      child: Container(
        width: 35,
        height: 35,
        color: Colors.teal,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
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
      // return IntrinsicWidth(
      //   child: Center(
      //     child: Stack(
      //       children: [
      //         Text(
      //           widget.currentChatRoom.name,
      //           style: const TextStyle(
      //               fontSize: 24,
      //               fontWeight: FontWeight.bold,
      //               color: Colors.teal
      //           ),
      //         ),
      //         Positioned(
      //           top: 0,
      //           right: 0,
      //           child: IconButton(
      //             onPressed: () {},
      //             icon: Icon(
      //               Icons.edit,
      //               size: 20,
      //               color: Colors.teal,
      //             ),
      //           ),
      //         )
      //       ],
      //     ),
      //   ),
      // );
      return IntrinsicWidth(
        child: Stack(
          // alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                widget.currentChatRoom.name,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal
                ),
              ),
            ),
            // const Align(
            //   alignment: Alignment.topRight,
            //   child: Icon(
            //     Icons.edit,
            //     size: 20,
            //     color: Colors.teal,
            //   ),
            // ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

}