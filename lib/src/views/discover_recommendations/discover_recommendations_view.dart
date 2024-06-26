import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/discover/discover_recommendation.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_bloc.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_event.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_state.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/shared_components/location_card.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

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
                  userRepository: RepositoryProvider.of<UserRepository>(context),
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
  bool isPremiumEnabled = false;
  bool hasUserMaxedOutFreeDiscoverQuota = false;
  late final DiscoverRecommendationsBloc _discoverRecommendationsBloc;
  List<DiscoverRecommendation> fetchedRecommendations = List.empty(growable: true);

  int currentSelectedRecommendationIndex = 0;
  CarouselController buttonCarouselController = CarouselController();

  List<String> alreadyViewedUserIds = [];
  int discoveredUsersViewedForMonthCountStateValue = 0;

  // Provide user with opportunity to discover outside of selected radius if user wants
  bool shouldIncreaseRadius = false;

  @override
  void initState() {
    super.initState();
    isPremiumEnabled = WidgetUtils.isPremiumEnabledForUser(context);

    _discoverRecommendationsBloc = BlocProvider.of<DiscoverRecommendationsBloc>(context);
    _discoverRecommendationsBloc.add(
        FetchUserDiscoverRecommendations(
          currentUserProfile: widget.currentUserProfile,
          shouldIncreaseRadius: shouldIncreaseRadius,
          limit: ConstantUtils.DEFAULT_DISCOVER_RECOMMENDATIONS_LIMIT,
          skip: 0,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Buddies', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _generateBody(),
      floatingActionButton: _generateFloatingActionButtons(),
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
    );
  }

  _generateFloatingActionButtons() {
    return BlocBuilder<DiscoverRecommendationsBloc, DiscoverRecommendationsState>(
        builder: (context, state) {
          if (state is DiscoverRecommendationsReady &&
              state.recommendations.isNotEmpty &&
              !_shouldUpgradeToPremium(state) &&
              !hasUserMaxedOutFreeDiscoverQuota
          ) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(100, 0, 0, 0),
                  width: 75,
                  height: 75,
                  child: FittedBox(
                    child: PointerInterceptor(
                      child: FloatingActionButton(
                          heroTag: "rejectButton",
                          onPressed: () {
                            final currentState = _discoverRecommendationsBloc.state;
                            if (currentState is DiscoverRecommendationsReady) {
                              _moveToNextItemAndRemoveCurrentItem(currentState);
                            }
                          },
                          backgroundColor: Colors.redAccent,
                          child: const Icon(Icons.close, color: Colors.white)
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 70, 0),
                  width: 75,
                  height: 75,
                  child: FittedBox(
                    child: PointerInterceptor(
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
    // track
  }

  _dispatchTrackViewNewDiscoveredUserEventIfNeeded(String newViewedUserId) {
    if (!alreadyViewedUserIds.contains(newViewedUserId)) {
      _discoverRecommendationsBloc.add(const TrackViewNewDiscoveredUserEvent());
      alreadyViewedUserIds.add(newViewedUserId);
    }
  }


  _showUpgradeToPremiumView() {
    return Center(
      child: IntrinsicHeight(
        child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Upgrade to premium to discover more users!",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                        ),
                      ),
                      WidgetUtils.spacer(15),
                      const Text(
                        "As part of your plan, you can discover 5 new people every month",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                        ),
                      ),
                      WidgetUtils.spacer(5),
                      const Text(
                        "Come back next month for more!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                        ),
                      ),
                      WidgetUtils.spacer(15),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          _goToAccountDetailsView();
                        },
                        child: const Text(
                            "Upgrade",
                            style: TextStyle(fontSize: 15, color: Colors.white)
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
        ),
      ),
    );
  }

  //_goToAccountDetailsView

  _shouldUpgradeToPremium(DiscoverRecommendationsReady state) {
    return !isPremiumEnabled && state.discoveredUsersViewedForMonthCount >= ConstantUtils.MAX_DISCOVERABLE_USERS_PER_MONTH_FREE;
  }

  _generateBody() {
    return BlocListener<DiscoverRecommendationsBloc, DiscoverRecommendationsState>(
        listener: (context, state) {
          if (state is DiscoverRecommendationsReady &&
              state.recommendations.isNotEmpty &&
              !_shouldUpgradeToPremium(state)
          ) {
            _dispatchTrackViewNewDiscoveredUserEventIfNeeded(state.recommendations.first.user.userId);
          }
        },
        child: BlocBuilder<DiscoverRecommendationsBloc, DiscoverRecommendationsState>(builder: (context, state) {
          if (state is DiscoverRecommendationsReady) {
            if (hasUserMaxedOutFreeDiscoverQuota || _shouldUpgradeToPremium(state)) {
              return _showUpgradeToPremiumView();
            }
            else {
              discoveredUsersViewedForMonthCountStateValue = state.discoveredUsersViewedForMonthCount;
              fetchedRecommendations = state.recommendations;
              return Column(
                children: WidgetUtils.skipNulls([
                  _showExtendedRadiusDiscoverTextIfNeeded(),
                  Expanded(child: _renderPagesOrEmptyScreen(state)),
                ]),
              );
            }
          }
          else {
            if (DeviceUtils.isAppRunningOnMobileBrowser()) {
              return WidgetUtils.progressIndicator();
            }
            else {
              return _skeletonLoadingScreen();
            }
          }
        }),
    );
  }

  _skeletonLoadingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: SingleChildScrollView(
          child: SkeletonLoader(
            period: const Duration(seconds: 2),
            highlightColor: Colors.teal,
            direction: SkeletonDirection.ltr,
            builder: _carouselSliderStub(),
          ),
        ),
      ),
    );
  }

  _showExtendedRadiusDiscoverTextIfNeeded() {
    if (shouldIncreaseRadius) {
      return GestureDetector(
        onTap: () {
          setState(() {
            shouldIncreaseRadius = false;
          });
          buttonCarouselController = CarouselController(); // This is done to reset "readiness" of controller
          _discoverRecommendationsBloc.add(FetchUserDiscoverRecommendations(
            currentUserProfile: widget.currentUserProfile,
            shouldIncreaseRadius: shouldIncreaseRadius,
            limit: ConstantUtils.DEFAULT_DISCOVER_RECOMMENDATIONS_LIMIT,
            skip: 0,
          ));
        },
        child: Column(
          children: [
            const Text(
              "You are discovering users beyond your chosen radius",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.teal,
              ),
            ),
            WidgetUtils.spacer(2.5),
            const Text(
              "Tap here to disable this.",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      );
    }
  }

  _renderPagesOrEmptyScreen(DiscoverRecommendationsReady state) {
    if (fetchedRecommendations.isNotEmpty) {
      return _carouselSlider(state.currentUserProfile, fetchedRecommendations, state.doesNextPageExist);
    }
    else {
      return _noResultsView();
    }
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
          GestureDetector(
            onTap: () {
              setState(() {
                shouldIncreaseRadius = true;
              });
              buttonCarouselController = CarouselController(); // This is done to reset "readiness" of controller
              _discoverRecommendationsBloc.add(
                  FetchUserDiscoverRecommendations(
                    currentUserProfile: widget.currentUserProfile,
                    shouldIncreaseRadius: shouldIncreaseRadius,
                    limit: ConstantUtils.DEFAULT_DISCOVER_RECOMMENDATIONS_LIMIT,
                    skip: 0,
                  )
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                "Alternatively, click here to discover users outside your search radius",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _carouselSliderStub() {
    final items = [1].map((recommendation) {
      return Builder(
        builder: (BuildContext context) {
          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal)
              ),
              child: _generateUserCardStub()
          );
        },
      );
    }).toList();

    return CarouselSlider(
        items: items,
        carouselController: buttonCarouselController,
        options: CarouselOptions(
          height: ScreenUtils.getScreenHeight(context) * 0.8,
          aspectRatio: 16/9,
          viewportFraction: 0.825,
          initialPage: currentSelectedRecommendationIndex,
          enableInfiniteScroll: false,
          reverse: false,
          enlargeCenterPage: true,
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _carouselSlider(
      PublicUserProfile currentUserProfile,
      List<DiscoverRecommendation> recommendations,
      bool doesNextPageExist
      ) {
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

    if (doesNextPageExist) {
      items.add(Builder(
        builder: (BuildContext context) {
          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal)
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              )
          );
        },
      ));
    }

    if (buttonCarouselController.ready) {
      buttonCarouselController.jumpToPage(currentSelectedRecommendationIndex);
    }
    return CarouselSlider(
        items: items,
        carouselController: buttonCarouselController,
        options: CarouselOptions(
          height: ScreenUtils.getScreenHeight(context) * 0.8,
          aspectRatio: 16/9,
          viewportFraction: 0.825,
          initialPage: currentSelectedRecommendationIndex,
          enableInfiniteScroll: false,
          reverse: false,
          enlargeCenterPage: true,
          onPageChanged: (page, reason) {
              if (page == recommendations.length - 2) { // Second last element of recommendations list
                if (doesNextPageExist) {
                  _discoverRecommendationsBloc.add(
                      FetchAdditionalUserDiscoverRecommendations(
                        currentUserProfile: widget.currentUserProfile,
                        shouldIncreaseRadius: shouldIncreaseRadius,
                        limit: ConstantUtils.DEFAULT_DISCOVER_RECOMMENDATIONS_LIMIT,
                        skip: recommendations.length,
                      )
                  );
                }
              }
              currentSelectedRecommendationIndex = page;
              if (page < recommendations.length) {
                _forcePlebUserToStopViewingUsersOrDispatchTrackingEvent(recommendations[page].user.userId);
              }
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _forcePlebUserToStopViewingUsersOrDispatchTrackingEvent(String newUserId) {
    if (!isPremiumEnabled &&
        (discoveredUsersViewedForMonthCountStateValue + alreadyViewedUserIds.length) >= ConstantUtils.MAX_DISCOVERABLE_USERS_PER_MONTH_FREE
    ) {
      setState(() {
        hasUserMaxedOutFreeDiscoverQuota = true;
      });
      WidgetUtils.showUpgradeToPremiumDialog(context, _goToAccountDetailsView);
      SnackbarUtils.showSnackBarShort(context, "Upgrade to premium to view more discovered users!");
    }
    else {
      _dispatchTrackViewNewDiscoveredUserEventIfNeeded(newUserId);
    }
  }

  _goToAccountDetailsView() {
    Navigator.pushReplacement(
      context,
      HomePage.route(defaultSelectedTab: HomePageState.accountDetails),
    );
  }

  _generateUserCardStub() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _generateUserHeaderStub(),
          WidgetUtils.spacer(5),
          _generateUserMatchedAttributesStub(),
          WidgetUtils.spacer(5),
          _generateLocationCardStub(),
        ],
      ),
    );
  }

  _generateUserCard(DiscoverRecommendation recommendation) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _generateUserHeader(recommendation),
          WidgetUtils.spacer(5),
          _generateUserMatchedAttributes(recommendation),
          WidgetUtils.spacer(5),
          _generateLocationCard(recommendation.user),
        ],
      ),
    );
  }

  _generateLocationCard(PublicUserProfile userProfile) {
    return Expanded(
        child: LocationCard(otherUserProfile: userProfile, currentUserProfile: widget.currentUserProfile,),
    );
  }

  _generateLocationCardStub() {
    return Container();
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
              children: WidgetUtils.skipNulls([
                _userFirstAndLastName(recommendation.user.firstName ?? "", recommendation.user.lastName ?? ""),
                WidgetUtils.spacer(5),
                _userHoursPerWeekOrUsername(recommendation.user, recommendation.matchedAttributes.hoursPerWeek),
                _generateDiscoverUserScore(recommendation.discoverScore.toDouble()),
                _generateOptionalGymText(recommendation)
              ]),
            ),
        ),
      ],
    );
  }

  _generateUserHeaderStub() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            child: _userAvatar(widget.currentUserProfile)
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              Center(
                child: Container(
                  width: 50,
                  height: 10,
                ),
              ),
              WidgetUtils.spacer(5),
              _generateDiscoverUserScore(50),
            ]),
          ),
        ),
      ],
    );
  }

  _generateOptionalGymText(DiscoverRecommendation recommendation) {
    if (recommendation.doesRecommendedUserGoToSameGym) {
      const style = TextStyle(fontSize: 12, color: Colors.teal);
      return const Text("You both go to the same gym!", textAlign: TextAlign.center, style: style);
    }
  }

  _generateDiscoverUserScore(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
          child: WidgetUtils.render180DegreeGauge(score),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child:  Column(
              children: [
                const Text("Match score", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
                WidgetUtils.spacer(5),
                Text("${score.toStringAsFixed(2)} %", textAlign: TextAlign.center, style: const TextStyle(fontSize: 10),),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _generateUserMatchedAttributes(DiscoverRecommendation recommendation) {
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

  Widget _generateUserMatchedAttributesStub() {
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
                Expanded(child: Container(width: 50, height: 10,)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                Expanded(child: Container(width: 50, height: 10,)),
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
                Expanded(child: Container(width: 50, height: 10,)),
                WidgetUtils.spacer(1),
                const VerticalDivider(color: Colors.teal,),
                WidgetUtils.spacer(1),
                Expanded(child: Container(width: 50, height: 10,)),
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