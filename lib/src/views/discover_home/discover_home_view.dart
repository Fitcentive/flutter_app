import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_bloc.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_event.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_state.dart';
import 'package:flutter_app/src/views/discover_recommendations/discover_recommendations_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/discover_user_preferences_view.dart';
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
          final currentState = state;
          if (currentState is DiscoverUserPreferencesFetched) {
            if (currentState.personalPreferences == null || currentState.fitnessPreferences == null || currentState.discoveryPreferences == null) {
              _navigateToDiscoverUserPreferences(currentState);
            }
          }
        },
        child: BlocBuilder<DiscoverHomeBloc, DiscoverHomeState>(
          builder: (context, state) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      "Discover people in your area to join you on your fitness journey",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      "Update your preferences for most accurate results",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  WidgetUtils.spacer(30),
                  _actionButton("Update Preferences", () {
                    if (state is DiscoverUserPreferencesFetched) {
                      _navigateToDiscoverUserPreferences(state);
                    }
                  }),
                  _actionButton("Discover Buddies", () {
                    _navigateToDiscoverRecommendations();
                  }),
                ],
              ),
            );
          },
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

  _navigateToDiscoverUserPreferences(DiscoverUserPreferencesFetched state) {
    Navigator.pushAndRemoveUntil(
        context,
        DiscoverUserPreferencesView.route(
          userProfile: widget.currentUserProfile,
          discoveryPreferences: state.discoveryPreferences,
          fitnessPreferences: state.fitnessPreferences,
          personalPreferences: state.personalPreferences,
        ), (route) => true
    ).then((value) {
      _discoverHomeBloc.add(FetchUserDiscoverPreferences(widget.currentUserProfile.userId));
    });
  }

  _navigateToDiscoverRecommendations() {
    Navigator.pushAndRemoveUntil(
        context,
        DiscoverRecommendationsView.route(
          userProfile: widget.currentUserProfile,
        ), (route) => true
    ).then((value) {
      // todo - refetch the user discovered list here
    });
  }
}