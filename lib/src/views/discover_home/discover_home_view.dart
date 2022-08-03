import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_bloc.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_event.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverHomeView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const DiscoverHomeView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<DiscoverHomeBloc>(
          create: (context) => DiscoverHomeBloc(
            discoverRepository: RepositoryProvider.of<DiscoverRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: DiscoverHomeView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return DiscoverHomeViewState();
  }
}

class DiscoverHomeViewState extends State<DiscoverHomeView> {

  late final DiscoverHomeBloc _discoverHomeBloc;

  @override
  void initState() {
    super.initState();
    _discoverHomeBloc = BlocProvider.of<DiscoverHomeBloc>(context);
    _discoverHomeBloc.add(FetchUserDiscoverPreferences(widget.currentUserProfile.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<DiscoverHomeBloc, DiscoverHomeState>(
        listener: (context, state) {
          if (state is DiscoverUserPreferencesFetched) {
            if (state.personalPreferences == null || state.fitnessPreferences == null || state.discoveryPreferences == null) {
              print("Going to other page now");
            }
            else {
              print("Staying over here");
            }
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text("Discover people in your area to join you on your fitness journey", style: TextStyle(fontSize: 20),),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text("Update your preferences for most accurate results", style: TextStyle(fontSize: 16),),
              ),
              WidgetUtils.spacer(30),
              _actionButton("Update Preferences", () {
                print("Update pressed");
              }),
              _actionButton("Discover Buddies", () {
                print("Update pressed");
              }),
            ],
          ),
        ),
      ),
    );
  }

  _actionButton(String text, VoidCallback onTap) {
    return ElevatedButton(
        onPressed: onTap,
        child: Text(text)
    );
  }
}