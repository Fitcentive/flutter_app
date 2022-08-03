import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/location_preference_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/transport_preference_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverUserPreferencesView extends StatefulWidget {
  static const String routeName = "discover-preferences";

  final PublicUserProfile userProfile;
  final UserDiscoveryPreferences? discoveryPreferences;
  final UserFitnessPreferences? fitnessPreferences;
  final UserPersonalPreferences? personalPreferences;

  const DiscoverUserPreferencesView({
    Key? key,
    required this.userProfile,
    required this.discoveryPreferences,
    required this.fitnessPreferences,
    required this.personalPreferences,
  }): super(key: key);

  static Route route({
      required PublicUserProfile userProfile,
      required UserDiscoveryPreferences? discoveryPreferences,
      required UserFitnessPreferences? fitnessPreferences,
      required UserPersonalPreferences? personalPreferences}) {

    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DiscoverUserPreferencesBloc>(
                create: (context) => DiscoverUserPreferencesBloc(
                  discoverRepository: RepositoryProvider.of<DiscoverRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: DiscoverUserPreferencesView(
              userProfile: userProfile,
              discoveryPreferences: discoveryPreferences,
              fitnessPreferences: fitnessPreferences,
              personalPreferences: personalPreferences
          ),
        )
    );

  }

  @override
  State createState() {
    return DiscoverUserPreferencesViewState();
  }
}

class DiscoverUserPreferencesViewState extends State<DiscoverUserPreferencesView> {
  final PageController _pageController = PageController();
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  Icon floatingActionButtonIcon = const Icon(Icons.navigate_next_sharp, color: Colors.white);

  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    _discoverUserPreferencesBloc.add(DiscoverUserPreferencesInitial(
      userProfile: widget.userProfile,
      discoveryPreferences: widget.discoveryPreferences,
      fitnessPreferences: widget.fitnessPreferences,
      personalPreferences: widget.personalPreferences,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Preferences', style: TextStyle(color: Colors.teal),)),
      body: _pageViews(),
      floatingActionButton: FloatingActionButton(
          onPressed: _onFloatingActionButtonPress,
          backgroundColor: Colors.teal,
          child: floatingActionButtonIcon
      ),
    );
  }

  VoidCallback? _onFloatingActionButtonPress() {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      final currentPage = _pageController.page;
      if (currentPage != null) {
        if (_isPageDataValid(currentPage.toInt(), currentState)) {
          _savePageData(currentPage.toInt(), currentState);
          _moveToNextPageOrPop(currentPage.toInt());
        }
        else {
          SnackbarUtils.showSnackBar(context, "Please complete the missing fields!");
        }
      }
    }
    return null;
  }

  void _moveToNextPageOrPop(int currentPage) {
    if (currentPage < 6) {
      // Move to next page if not at last page
      _pageController.animateToPage(currentPage + 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn
      );
    }
    else {
      // Go back to previous screen
      Navigator.pop(context);
    }
  }

  void _savePageData(int pageNumber, UserDiscoverPreferencesModified state) {
    switch (pageNumber) {
      case 0:
        _discoverUserPreferencesBloc.add(
            UserDiscoverLocationPreferencesChanged(
                userProfile: state.userProfile,
                locationCenter: state.locationCenter!,
                locationRadius: state.locationRadius!
            )
        );
        return;
      case 1:
        _discoverUserPreferencesBloc.add(
            UserDiscoverPreferredTransportModePreferencesChanged(
                userProfile: state.userProfile,
                preferredTransportMode: state.preferredTransportMode!,
            )
        );
        return;
      case 2:
        _discoverUserPreferencesBloc.add(
            UserDiscoverActivityPreferencesChanged(
              userProfile: state.userProfile,
              activitiesInterestedIn: state.activitiesInterestedIn!,
            )
        );
        return;
      case 3:
        _discoverUserPreferencesBloc.add(
            UserDiscoverFitnessGoalsPreferencesChanged(
              userProfile: state.userProfile,
              fitnessGoals: state.fitnessGoals!,
            )
        );
        return;
      case 4:
        _discoverUserPreferencesBloc.add(
            UserDiscoverBodyTypePreferencesChanged(
              userProfile: state.userProfile,
              desiredBodyTypes: state.desiredBodyTypes!,
            )
        );
        return;
      case 5:
        _discoverUserPreferencesBloc.add(
            UserDiscoverGenderPreferencesChanged(
              userProfile: state.userProfile,
              gendersInterestedIn: state.desiredBodyTypes!,
              minimumAge: state.minimumAge!,
              maximumAge: state.maximumAge!,
            )
        );
        return;
      case 6:
        _discoverUserPreferencesBloc.add(
            UserDiscoverDayPreferencesChanged(
              userProfile: state.userProfile,
              preferredDays: state.preferredDays!,
              hoursPerWeek: state.hoursPerWeek!,
            )
        );
        return;
      default:
        return;
    }
  }

  bool _isPageDataValid(int pageNumber, UserDiscoverPreferencesModified state) {
    switch (pageNumber) {
      case 0:
        // Validate location data
        return state.locationRadius != null && state.locationCenter != null;
      case 1:
        // Validate preferredTransportData
        return state.preferredTransportMode != null;
      case 2:
        // Validate activities
        return state.activitiesInterestedIn != null;
      case 3:
        // Validate fitnessGoals
        return state.fitnessGoals != null;
      case 4:
        // Validate body types
        return state.desiredBodyTypes != null;
      case 5:
        // Validate personal prefs
        return state.gendersInterestedIn != null && state.minimumAge != null && state.maximumAge != null;
      case 6:
        // Validate personal prefs
        return state.preferredDays != null && state.hoursPerWeek != null;
      default:
        return false;
    }
  }

  Widget _pageViews() {
    return BlocBuilder<DiscoverUserPreferencesBloc, DiscoverUserPreferencesState>(builder: (context, state) {
      if (state is UserDiscoverPreferencesModified) {
        return PageView(
          controller: _pageController,
          onPageChanged: (pageNumber) {
            if (pageNumber == 6) {
              setState(() {
                floatingActionButtonIcon = const Icon(Icons.save, color: Colors.white);
              });
            }
          },
          physics: const NeverScrollableScrollPhysics(),
          children: [
            LocationPreferenceView(
                userProfile: state.userProfile,
                locationCenter: state.locationCenter,
                locationRadius: state.locationRadius,
            ),
            TransportPreferenceView(
                userProfile: state.userProfile,
                preferredTransportMethod: state.preferredTransportMode
            )
          ],
        );
      }
      else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    });
  }
}
