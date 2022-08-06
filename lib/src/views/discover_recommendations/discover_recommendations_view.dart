import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/models/discover/discover_recommendation.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_bloc.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_event.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_state.dart';
import 'package:flutter_app/src/views/shared_components/location_card.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DiscoverRecommendationsView extends StatefulWidget {
  static const String routeName = "discover-recommendations";

  final PublicUserProfile currentUserProfile;

  const DiscoverRecommendationsView({
    Key? key,
    required this.currentUserProfile,
  }): super(key: key);

  static Route route({required PublicUserProfile userProfile}) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DiscoverRecommendationsBloc>(
                create: (context) => DiscoverRecommendationsBloc(
                  discoverRepository: RepositoryProvider.of<DiscoverRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: DiscoverRecommendationsView(currentUserProfile: userProfile),
        )
    );

  }

  @override
  State createState() {
    return DiscoverRecommendationsViewState();
  }
}

class DiscoverRecommendationsViewState extends State<DiscoverRecommendationsView> {
  late final DiscoverRecommendationsBloc _discoverRecommendationsBloc;
  List<DiscoverRecommendation> fetchedRecommendations = List.empty(growable: true);

  int currentSelectedRecommendationIndex = 0;
  CarouselController buttonCarouselController = CarouselController();


  @override
  void initState() {
    super.initState();

    _discoverRecommendationsBloc = BlocProvider.of<DiscoverRecommendationsBloc>(context);
    _discoverRecommendationsBloc.add(FetchUserDiscoverRecommendations(widget.currentUserProfile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Buddies', style: TextStyle(color: Colors.teal),)),
      body: _generateBody(),
      floatingActionButton: _generateFloatingActionButtons(),
    );
  }

  _generateFloatingActionButtons() {
    return BlocBuilder<DiscoverRecommendationsBloc, DiscoverRecommendationsState>(
        builder: (context, state) {
          if (state is DiscoverRecommendationsReady && state.recommendations.isNotEmpty) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(100, 0, 0, 0),
                  width: 75,
                  height: 75,
                  child: FittedBox(
                    child: FloatingActionButton(
                        heroTag: "rejectButton",
                        onPressed: () {
                          final currentState = _discoverRecommendationsBloc.state;
                          if (currentState is DiscoverRecommendationsReady) {
                            _moveToNextItemAndRemoveCurrentItem(currentState);
                          }
                        },
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.close, color: Colors.white)
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 70, 0),
                  width: 75,
                  height: 75,
                  child: FittedBox(
                    child: FloatingActionButton(
                        heroTag: "connectButton",
                        onPressed: () {
                          final currentState = _discoverRecommendationsBloc.state;
                          if (currentState is DiscoverRecommendationsReady) {
                            _discoverRecommendationsBloc.add(
                                UpsertNewlyDiscoveredUser(
                                    currentUserId: widget.currentUserProfile.userId,
                                    newUserId: currentState.recommendations[currentSelectedRecommendationIndex].user.userId
                                )
                            );
                            _moveToNextItemAndRemoveCurrentItem(currentState);
                          }
                        },
                        backgroundColor: Colors.teal,
                        child: const Icon(Icons.check, color: Colors.white)
                    ),
                  ),
                )
              ],
            );
          }
          else {
            // Dummy widget return
            return WidgetUtils.spacer(0);
          }
    });
  }

  _moveToNextItemAndRemoveCurrentItem(DiscoverRecommendationsReady currentState) {
    final indexToDelete = currentSelectedRecommendationIndex;
    buttonCarouselController
        .nextPage(duration: const Duration(milliseconds: 150))
        .then((value) {
            final tempRecommendations = fetchedRecommendations;
            tempRecommendations.removeWhere((element) => element.user.userId == fetchedRecommendations[indexToDelete].user.userId);
            setState(() {
              fetchedRecommendations = tempRecommendations;
              currentSelectedRecommendationIndex = max(currentSelectedRecommendationIndex - 1, 0);
            });
    });
  }

  _generateBody() {
    return BlocBuilder<DiscoverRecommendationsBloc, DiscoverRecommendationsState>(builder: (context, state) {
      if (state is DiscoverRecommendationsReady) {
        fetchedRecommendations = state.recommendations;
        if (fetchedRecommendations.isNotEmpty) {
          return _carouselSlider(state.currentUserProfile, fetchedRecommendations);
        }
        else {
          return _noResultsView();
        }
      }
      else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    });
  }

  _noResultsView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text("No results found", style: TextStyle(fontSize: 20),),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              "Update your preferences for most accurate results",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _carouselSlider(PublicUserProfile currentUserProfile, List<DiscoverRecommendation> recommendations) {
    final items = recommendations.map((recommendation) {
      return Builder(
        builder: (BuildContext context) {
          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal)
              ),
              child: _generateUserCard(recommendation)
          );
        },
      );
    }).toList();
    if (buttonCarouselController.ready) {
      buttonCarouselController.jumpToPage(currentSelectedRecommendationIndex);
    }
    return CarouselSlider(
        items: items,
        carouselController: buttonCarouselController,
        options: CarouselOptions(
          height: ScreenUtils.getScreenHeight(context) * 0.75,
          aspectRatio: 16/9,
          viewportFraction: 0.825,
          initialPage: currentSelectedRecommendationIndex,
          enableInfiniteScroll: false,
          reverse: false,
          enlargeCenterPage: true,
          onPageChanged: (page, reason) {
              currentSelectedRecommendationIndex = page;
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _generateUserCard(DiscoverRecommendation recommendation) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _generateUserHeader(recommendation),
          const Padding(padding: EdgeInsets.all(10)),
          _generateUserMatchedAttributes(recommendation),
          LocationCard(userProfile: recommendation.user)
        ],
      ),
    );
  }

  _generateUserHeader(DiscoverRecommendation recommendation) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            child: _userAvatar(recommendation.user)
        ),
        Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _userFirstAndLastName(recommendation.user.firstName ?? "", recommendation.user.lastName ?? ""),
                WidgetUtils.spacer(5),
                _userHoursPerWeekOrUsername(recommendation.user, recommendation.matchedAttributes.hoursPerWeek),
              ],
            ),
        ),
      ],
    );
  }

  Widget _generateUserMatchedAttributes(DiscoverRecommendation recommendation) {
    return SizedBox(
      height: 275,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Expanded(child: Text("Similar activities", style: TextStyle(fontWeight: FontWeight.bold),)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                const Expanded(child: Text("Similar goals", style: TextStyle(fontWeight: FontWeight.bold),)),
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
                Expanded(child: _generateItemsMatchedOn(recommendation.matchedAttributes.activities)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                Expanded(child: _generateItemsMatchedOn(recommendation.matchedAttributes.fitnessGoals)),
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
                Expanded(child: _generateItemsMatchedOn(recommendation.matchedAttributes.preferredDays)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                Expanded(child: _generateItemsMatchedOn(recommendation.matchedAttributes.bodyTypes)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _generateItemsMatchedOn(List<String>? items) {
    if (items == null) {
      return const Center(
        child: Text("No matches on this attribute", style: TextStyle(fontSize: 12)),
      );
    }
    else {
      return Text(items.join(", "), style: const TextStyle(fontSize: 12),);
    }
  }

  _goToUserProfilePage(PublicUserProfile userProfile) {
    Navigator.pushAndRemoveUntil(
        context,
        UserProfileView.route(userProfile, widget.currentUserProfile),
            (route) => true
    );
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

  Widget _userUsername(String? username) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    if (username != null) {
      return Text("@$username", textAlign: TextAlign.center, style: style);
    }
    return const Text("", textAlign: TextAlign.center, style: style);
  }

  Widget _userHoursPerWeekOrUsername(PublicUserProfile userProfile, String? hoursPerWeek) {
    const style = TextStyle(fontSize: 14, color: Colors.teal);
    if (hoursPerWeek != null) {
      return Text(hoursPerWeek, textAlign: TextAlign.center, style: style);
    }
    else {
      return _userUsername(userProfile.username);
    }
  }

}