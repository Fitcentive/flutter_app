import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_bloc.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_event.dart';
import 'package:flutter_app/src/views/discover_home/bloc/discover_home_state.dart';
import 'package:flutter_app/src/views/discover_recommendations/discover_recommendations_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/discover_user_preferences_view.dart';
import 'package:flutter_app/src/views/discovered_user/discovered_user_view.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

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
  static const double _scrollThreshold = 200.0;
  final PanelController _panelController = PanelController();

  late final DiscoverHomeBloc _discoverHomeBloc;
  List<PublicUserProfile> discoveredUserProfiles = List.empty(growable: true);
  final _scrollController = ScrollController();

  String? selectedUserId;
  bool isDataBeingRequested = false;

  @override
  void initState() {
    super.initState();
    _discoverHomeBloc = BlocProvider.of<DiscoverHomeBloc>(context);
    _discoverHomeBloc.add(FetchUserDiscoverData(widget.currentUserProfile.userId));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        isDataBeingRequested = true;
        _discoverHomeBloc.add(FetchMoreDiscoveredUsers(widget.currentUserProfile.userId));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<DiscoverHomeBloc, DiscoverHomeState>(
        listener: (context, state) {
          final currentState = state;
          if (currentState is DiscoverUserDataFetched) {
            if (currentState.personalPreferences == null ||
                currentState.fitnessPreferences == null ||
                currentState.discoveryPreferences == null
            ) {
              _navigateToDiscoverUserPreferences(currentState);
            }
          }
        },
        child: BlocBuilder<DiscoverHomeBloc, DiscoverHomeState>(
          builder: (context, state) {
            if (state is DiscoverUserDataFetched) {
                isDataBeingRequested = false;
                discoveredUserProfiles = state.discoveredUserProfiles;
                selectedUserId ??= discoveredUserProfiles.isNotEmpty ? discoveredUserProfiles.first.userId : null;
                if (discoveredUserProfiles.isEmpty) {
                  return _showEmptyDiscoveredUserProfilesScreen(state);
                }
                else {
                  return _showDiscoveredUserListAndButtons(state);
                }
            }
            else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  _showDiscoveredUserListAndButtons(DiscoverUserDataFetched state) {
    return SlidingUpPanel(
      controller: _panelController,
      minHeight: 0,
      maxHeight: ScreenUtils.getScreenHeight(context) * 0.75,
      panel: _generateSlidingPanel(state),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _actionButton("Update Preferences", () {
                    _navigateToDiscoverUserPreferences(state);
                  }),
                ),
                WidgetUtils.spacer(5),
                Expanded(
                  child: _actionButton("Discover Buddies", () {
                    _navigateToDiscoverRecommendations();
                  }),
                )
              ],
            ),
          ),
          WidgetUtils.spacer(5),
          Expanded(
            child: _userResultsList(state),
          ),
        ],
      ),
    );
  }

  _userResultsList(DiscoverUserDataFetched state) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: state.doesNextPageExist ? discoveredUserProfiles.length + 1 : discoveredUserProfiles.length,
          itemBuilder: (context, index) {
            if (index >= discoveredUserProfiles.length) {
              return const Center(child: CircularProgressIndicator());
            }
            else {
              return _userSearchResultItem(discoveredUserProfiles[index]);
            }
          }
      ),
    );
  }

  Widget _userSearchResultItem(PublicUserProfile userProfile) {
    return Dismissible(
      key: Key(userProfile.userId),
      onDismissed: (direction) {
        if (selectedUserId == userProfile.userId) {
          selectedUserId = null;
        }
        _discoverHomeBloc.add(
            RemoveUserFromListOfDiscoveredUsers(
                currentUserId: widget.currentUserProfile.userId,
                discoveredUserId: userProfile.userId
            )
        );
        setState(() {
          discoveredUserProfiles.removeWhere((element) => element.userId == userProfile.userId);
        });
        SnackbarUtils.showSnackBar(context, "Removed ${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""} from list of discovered people");
      },
      background: Container(
        color: Colors.teal,
      ),
      child: ListTile(
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
              image: ImageUtils.getUserProfileImage(userProfile, 100, 100),
            ),
          ),
        ),
        onTap: () {
          setState(() {
            selectedUserId = userProfile.userId;
            _showSlidingUpViewWithUserProfile();
          });
        },
      ),
    );
  }

  _generateSlidingPanel(DiscoverUserDataFetched state) {
    final userProfile = state.discoveredUserProfiles.firstWhere((element) => element.userId == selectedUserId);
    return DiscoveredUserView.withBloc(
        currentUserProfile: widget.currentUserProfile,
        otherUserId: userProfile.userId,
        fitnessPreferences: state.fitnessPreferences,
        personalPreferences: state.personalPreferences,
        key: Key(userProfile.userId + DateTime.now().toString())
    );
  }

  _showSlidingUpViewWithUserProfile() {
    _panelController.animatePanelToPosition(1.0, duration: const Duration(milliseconds: 250));
  }

  _showEmptyDiscoveredUserProfilesScreen(DiscoverUserDataFetched state) {
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
            _navigateToDiscoverUserPreferences(state);
          }),
          WidgetUtils.spacer(5),
          _actionButton("Discover Buddies", () {
            _navigateToDiscoverRecommendations();
          }),
        ],
      ),
    );
  }

  _actionButton(String text, VoidCallback onTap) {
    return ElevatedButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.resolveWith<EdgeInsetsGeometry>(
                (Set<MaterialState> states) {
              return const EdgeInsets.all(10);
            },
          ),
        ),
        onPressed: onTap,
        child: Text(text, textAlign: TextAlign.center,)
    );
  }

  _navigateToDiscoverUserPreferences(DiscoverUserDataFetched state) {
    Navigator.pushAndRemoveUntil(
        context,
        DiscoverUserPreferencesView.route(
          userProfile: widget.currentUserProfile,
          discoveryPreferences: state.discoveryPreferences,
          fitnessPreferences: state.fitnessPreferences,
          personalPreferences: state.personalPreferences,
        ), (route) => true
    ).then((value) {
      _discoverHomeBloc.add(FetchUserDiscoverData(widget.currentUserProfile.userId));
    });
  }

  _navigateToDiscoverRecommendations() {
    Navigator.pushAndRemoveUntil(
        context,
        DiscoverRecommendationsView.route(
          userProfile: widget.currentUserProfile,
        ), (route) => true
    ).then((value) {
      _discoverHomeBloc.add(FetchUserDiscoverData(widget.currentUserProfile.userId));
    });
  }
}