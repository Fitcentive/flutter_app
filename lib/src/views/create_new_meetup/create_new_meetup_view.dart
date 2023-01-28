import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateNewMeetupView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const CreateNewMeetupView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<MeetupHomeBloc>(
          create: (context) => MeetupHomeBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: CreateNewMeetupView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return CreateNewMeetupViewState();
  }
}

class CreateNewMeetupViewState extends State<CreateNewMeetupView> {
  static const double _scrollThreshold = 200.0;

  bool isRequestingMoreData = false;
  bool _isFloatingButtonVisible = true;

  final _scrollController = ScrollController();
  late final MeetupHomeBloc _meetupHomeBloc;

  @override
  void initState() {
    super.initState();

    // _meetupHomeBloc = BlocProvider.of<MeetupHomeBloc>(context);
    // _meetupHomeBloc.add(FetchUserMeetupData(widget.currentUserProfile.userId));
  }

  // todo - work on this

  @override
  Widget build(BuildContext context) {
    return Text("Heelo");
  }
}