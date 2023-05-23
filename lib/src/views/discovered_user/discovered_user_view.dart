import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_gym_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_bloc.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_event.dart';
import 'package:flutter_app/src/views/discovered_user/bloc/discovered_user_state.dart';
import 'package:flutter_app/src/views/shared_components/location_card.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoveredUserView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final UserFitnessPreferences? currentUserFitnessPreferences;
  final UserPersonalPreferences? currentUserPersonalPreferences;
  final UserGymPreferences? currentUserGymPreferences;
  final String otherUserId;

  const DiscoveredUserView({
    Key? key,
    required this.currentUserProfile,
    required this.otherUserId,
    required this.currentUserFitnessPreferences,
    required this.currentUserPersonalPreferences,
    required this.currentUserGymPreferences,
  }): super(key: key);

  static Widget withBloc({
    Key? key,
    required PublicUserProfile currentUserProfile,
    required UserFitnessPreferences? fitnessPreferences,
    required UserPersonalPreferences? personalPreferences,
    required UserGymPreferences? gymPreferences,
    required String otherUserId
  }
  ) => MultiBlocProvider(
    providers: [
      BlocProvider<DiscoveredUserBloc>(
          create: (context) => DiscoveredUserBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            discoverRepository: RepositoryProvider.of<DiscoverRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: DiscoveredUserView(
      currentUserProfile: currentUserProfile,
      otherUserId: otherUserId,
      currentUserFitnessPreferences: fitnessPreferences,
      currentUserPersonalPreferences: personalPreferences,
      currentUserGymPreferences: gymPreferences,
      key: key,
    ),
  );

  @override
  State createState() {
    return DiscoveredUserViewState();
  }

}

class DiscoveredUserViewState extends State<DiscoveredUserView> {
  late final DiscoveredUserBloc _discoveredUserBloc;

  @override
  void initState() {
    super.initState();

    _discoveredUserBloc = BlocProvider.of<DiscoveredUserBloc>(context);
    _discoveredUserBloc.add(FetchDiscoveredUserPreferences(widget.currentUserProfile.userId, widget.otherUserId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DiscoveredUserBloc, DiscoveredUserState>(
          builder: (context, state) {
            if (state is DiscoveredUserPreferencesFetched) {
              return _generateUserCard(state);
            }
            else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }
      ),
    );
  }

  _generateUserCard(DiscoveredUserPreferencesFetched state) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.teal)
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _generateUserHeader(state),
          WidgetUtils.spacer(5),
          _generateUserMatchedAttributes(state),
          WidgetUtils.spacer(5),
          _generateLocationCard(state.otherUserProfile),
        ],
      ),
    );
  }

  _generateDiscoverUserScore(double score) {
    // RadialNeedlePointer requires range to be in 20-80 because we are only using 180 degs
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetUtils.render180DegreeGauge(score),
        WidgetUtils.spacer(10),
        Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
          child: Column(
            children: [
              const Text("Match score", textAlign: TextAlign.center, style: TextStyle(fontSize: 12),),
              WidgetUtils.spacer(5),
              Text("${score.toStringAsFixed(2)} %", textAlign: TextAlign.center, style: const TextStyle(fontSize: 10),),
            ],
          ),
        ),
      ],
    );
  }

  _generateUserHeader(DiscoveredUserPreferencesFetched state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            child: _userAvatar(state.otherUserProfile)
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              _userFirstAndLastName(state.otherUserProfile.firstName ?? "", state.otherUserProfile.lastName ?? ""),
              WidgetUtils.spacer(5),
              _userHoursPerWeek(state.personalPreferences, widget.currentUserPersonalPreferences),
              WidgetUtils.spacer(15),
              _generateDiscoverUserScore(state.discoverScore.toDouble()),
              _generateOptionalGymText(state.gymPreferences),
            ]),
          ),
        ),
      ],
    );
  }

  _generateOptionalGymText(UserGymPreferences? prefs) {
    if (prefs != null && prefs.gymLocationId != null && widget.currentUserGymPreferences != null) {
      if ((widget.currentUserGymPreferences!.gymLocationId ?? "") == prefs.gymLocationId) {
        const style = TextStyle(fontSize: 12, color: Colors.teal);
        return const Text("You both go to the same gym!", textAlign: TextAlign.center, style: style);
      }
    }
  }


  Widget _userHoursPerWeek(
      UserPersonalPreferences? otherUserPersonalPreferences,
      UserPersonalPreferences? currentUserPersonalPreferences
  ) {
    if (otherUserPersonalPreferences != null) {
      final color = currentUserPersonalPreferences?.hoursPerWeek.floor() == otherUserPersonalPreferences.hoursPerWeek.floor() ?
                      Colors.teal : null;
      final style = TextStyle(fontSize: 14, color: color);
      return Text("${otherUserPersonalPreferences.hoursPerWeek.toString()} hours per week", textAlign: TextAlign.center, style: style);
    }
    else {
      return const Text("", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.teal));
    }
  }

  Widget _userAvatar(PublicUserProfile userProfile) {
    return InkWell(
      onTap: () {
        _goToUserProfilePage(userProfile);
      },
      child: CircleAvatar(
        radius: 50,
        child: Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: ImageUtils.getUserProfileImage(userProfile, 200, 200),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userFirstAndLastName(String firstName, String lastName) {
    return Center(
      child: Text(
        "$firstName $lastName",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _goToUserProfilePage(PublicUserProfile userProfile) {
    Navigator.pushAndRemoveUntil(
        context,
        UserProfileView.route(userProfile, widget.currentUserProfile),
            (route) => true
    );
  }

  Widget _generateUserMatchedAttributes(DiscoveredUserPreferencesFetched state) {
    return Container(
      // height: 250,
      constraints: const BoxConstraints(
          minHeight: 100,
          minWidth: double.infinity,
          maxHeight: 250
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Expanded(child: Text("Interested activities", style: TextStyle(fontWeight: FontWeight.bold),)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                const Expanded(child: Text("Fitness goals", style: TextStyle(fontWeight: FontWeight.bold),)),
              ],
            ),
          ),
          WidgetUtils.spacer(1),
          const Divider(color: Colors.teal,),
          WidgetUtils.spacer(1),
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _generateItemsMatchedOn(state.fitnessPreferences?.activitiesInterestedIn, widget.currentUserFitnessPreferences?.activitiesInterestedIn)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                Expanded(child: _generateItemsMatchedOn(state.fitnessPreferences?.fitnessGoals, widget.currentUserFitnessPreferences?.fitnessGoals)),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          const Divider(color: Colors.teal,),
          WidgetUtils.spacer(2.5),
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Expanded(child: Text("Preferred days", style: TextStyle(fontWeight: FontWeight.bold),)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                const Expanded(child: Text("Desired body type", style: TextStyle(fontWeight: FontWeight.bold),)),
              ],
            ),
          ),
          WidgetUtils.spacer(1),
          const Divider(color: Colors.teal,),
          WidgetUtils.spacer(1),
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _generateItemsMatchedOn(state.personalPreferences?.preferredDays, widget.currentUserPersonalPreferences?.preferredDays)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                Expanded(child: _generateItemsMatchedOn(state.fitnessPreferences?.desiredBodyTypes, widget.currentUserFitnessPreferences?.desiredBodyTypes)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _generateLocationCard(PublicUserProfile userProfile) {
    return Expanded(
      child: LocationCard(otherUserProfile: userProfile, currentUserProfile: widget.currentUserProfile,),
    );
  }

  _generateItemsMatchedOn(List<String>? otherUserItems, List<String>? currentUserItems) {
    if (otherUserItems == null) {
      return const Center(
        child: Text("No data for this attribute", style: TextStyle(fontSize: 12)),
      );
    }
    else {
      return SizedBox(
        height: 62.5,
        child: SingleChildScrollView(
          child: Wrap(
            children: List<Widget>.generate(
                otherUserItems.length,
                    (index) {
                      final currentItem = otherUserItems[index];
                      final isCurrentItemPartOfCurrentUserItems = currentUserItems?.contains(currentItem) ?? false;
                      final color = isCurrentItemPartOfCurrentUserItems ? Colors.teal : null;
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Text(currentItem, style: TextStyle(fontSize: 12, color: color)),
                      );
                    }),
          ),
        ),
      );
    }
  }
}