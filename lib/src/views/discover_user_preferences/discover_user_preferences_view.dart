import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/activity_preferences_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/body_type_preferences_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/days_preference_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/gender_preferences_view.dart';
import 'package:flutter_app/src/views/discover_user_preferences/views/goals_preferences_view.dart';
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

  Icon floatingActionButtonIcon = const Icon(Icons.navigate_next, color: Colors.white);
  Widget? dynamicActionButtons;

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

    dynamicActionButtons = _singleFloatingActionButton();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Preferences', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _pageViews(),
      floatingActionButton: dynamicActionButtons,
    );
  }

  _singleFloatingActionButton() {
    return FloatingActionButton(
        onPressed: _onActionButtonPress,
        backgroundColor: Colors.teal,
        child: floatingActionButtonIcon
    );
  }

  _dynamicFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(30, 0, 0, 0),
          child: FloatingActionButton(
              heroTag: "button1",
              onPressed: _onBackFloatingActionButtonPress,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.navigate_before, color: Colors.white)
          ),
        ),
        FloatingActionButton(
            heroTag: "button2",
            onPressed: _onActionButtonPress,
            backgroundColor: Colors.teal,
            child: floatingActionButtonIcon
        )
      ],
    );
  }

  VoidCallback? _onBackFloatingActionButtonPress() {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      final currentPage = _pageController.page;
      if (currentPage != null) {
        _goToPreviousPageOrNothing(currentPage.toInt());
      }
    }
    return null;
  }

  VoidCallback? _onActionButtonPress() {
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

  void _goToPreviousPageOrNothing(int currentPage) {
    if (currentPage != 0) {
      // Move to previous page if not at first page
      _pageController.animateToPage(currentPage - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut
      );
    }
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
      SnackbarUtils.showSnackBar(context, "Discover preferences updated successfully!");
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
              gendersInterestedIn: state.gendersInterestedIn!,
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
        return state.activitiesInterestedIn != null && state.activitiesInterestedIn!.isNotEmpty;
      case 3:
        // Validate fitnessGoals
        return state.fitnessGoals != null && state.fitnessGoals!.isNotEmpty;
      case 4:
        // Validate body types
        return state.desiredBodyTypes != null && state.desiredBodyTypes!.isNotEmpty;
      case 5:
        // Validate personal prefs
        return state.gendersInterestedIn != null && state.gendersInterestedIn!.isNotEmpty
            && state.minimumAge != null && state.maximumAge != null;
      case 6:
        // Validate personal prefs
        return state.preferredDays != null && state.preferredDays!.isNotEmpty && state.hoursPerWeek != null;
      default:
        return false;
    }
  }

  _changeButtonIconIfNeeded(int pageNumber) {
    if (pageNumber == 6) {
      setState(() {
        floatingActionButtonIcon = const Icon(Icons.save, color: Colors.white);
      });
    }
    else {
      setState(() {
        floatingActionButtonIcon = const Icon(Icons.navigate_next, color: Colors.white);
      });
    }
  }

  _changeFloatingActionButtonsIfNeeded(int pageNumber) {
    if (pageNumber == 0) {
      setState(() {
        dynamicActionButtons =  _singleFloatingActionButton();
      });
    }
    else {
      setState(() {
        dynamicActionButtons = _dynamicFloatingActionButtons();
      });
    }
  }

  Widget _pageViews() {
    return BlocBuilder<DiscoverUserPreferencesBloc, DiscoverUserPreferencesState>(builder: (context, state) {
      if (state is UserDiscoverPreferencesModified) {
        return PageView(
          controller: _pageController,
          onPageChanged: (pageNumber) {
            _changeButtonIconIfNeeded(pageNumber);
            _changeFloatingActionButtonsIfNeeded(pageNumber);
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
            ),
            ActivityPreferencesView(
                userProfile: state.userProfile,
                activitiesInterestedIn: state.activitiesInterestedIn
            ),
            GoalsPreferencesView(
                userProfile: state.userProfile,
                fitnessGoals: state.fitnessGoals
            ),
            BodyTypePreferencesView(
                userProfile: state.userProfile,
                bodyTypes: state.desiredBodyTypes
            ),
            GenderPreferencesView(
                userProfile: state.userProfile,
                preferredGenders: state.gendersInterestedIn,
                minimumAge: state.minimumAge,
                maximumAge: state.maximumAge
            ),
            DaysPreferencesView(
              userProfile: state.userProfile,
              preferredDays: state.preferredDays,
              hoursPerWeek: state.hoursPerWeek,
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
