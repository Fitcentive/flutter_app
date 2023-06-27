import 'package:auto_size_text/auto_size_text.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
import 'package:flutter_app/src/views/exercise_diary/exercise_diary_view.dart';
import 'package:flutter_app/src/views/food_diary/food_diary_view.dart';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/meetup_comments_list.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:intl/intl.dart';


typedef AvailabilitiesChangedCallback = void Function(List<List<bool>> availabilitiesChanged);
typedef SearchLocationViewUpdateBlocCallback = void Function(Location location);
typedef SelectedTabCallback = void Function(int currentSelectedPage);

class MeetupTabs extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final bool isAvailabilitySelectHappening;
  final Map<String, List<MeetupAvailabilityUpsert>> userMeetupAvailabilities;
  final List<PublicUserProfile> selectedUserProfilesToShowDetailsFor;
  final Meetup currentMeetup;

  final List<PublicUserProfile> selectedMeetupParticipantUserProfiles;
  final Location? selectedMeetupLocation;
  final String? selectedMeetupLocationId;
  final String? selectedMeetupLocationFsqId;

  final List<Either<FoodGetResult, FoodGetResultSingleServing>> rawFoodEntries;
  final Map<String, AllDiaryEntries> participantDiaryEntriesMap;

  final AvailabilitiesChangedCallback availabilitiesChangedCallback;

  final VoidCallback editAvailabilitiesButtonCallback;
  final VoidCallback cancelEditAvailabilitiesButtonCallback;
  final VoidCallback saveAvailabilitiesButtonCallback;

  final SelectedTabCallback currentSelectedTabCallback;

  final SearchLocationViewUpdateBlocCallback searchLocationViewUpdateBlocCallback;
  final VoidCallback searchLocationViewUpdateMeetupLocationViaBlocCallback;

  const MeetupTabs({
    super.key,
    required this.currentUserProfile,
    required this.isAvailabilitySelectHappening,
    required this.userMeetupAvailabilities,

    // Note - when it comes to availability, parent determined behaviour that this can include multiple values
    // Otherwise - it only has one value in case of showing associated diary entries
    required this.selectedUserProfilesToShowDetailsFor,

    required this.currentMeetup,

    required this.selectedMeetupParticipantUserProfiles,
    required this.selectedMeetupLocation,
    required this.selectedMeetupLocationId,
    required this.selectedMeetupLocationFsqId,

    required this.rawFoodEntries,
    required this.participantDiaryEntriesMap,

    required this.availabilitiesChangedCallback,

    required this.editAvailabilitiesButtonCallback,
    required this.cancelEditAvailabilitiesButtonCallback,
    required this.saveAvailabilitiesButtonCallback,

    required this.currentSelectedTabCallback,

    required this.searchLocationViewUpdateBlocCallback,
    required this.searchLocationViewUpdateMeetupLocationViaBlocCallback,
  });

  @override
  State<StatefulWidget> createState() {
    return MeetupTabsState();
  }

}

class MeetupTabsState extends State<MeetupTabs> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const int MAX_TABS = 4;

  late final TabController _tabController;

  late String selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: MAX_TABS);
    _tabController.addListener(() {
      widget.currentSelectedTabCallback(_tabController.index);
    });

    selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor = widget.selectedMeetupParticipantUserProfiles.first.userId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.location_on, color: Colors.teal,),
                  child: Text(
                    "Location",
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.teal,
                        fontSize: 10
                    ),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.event_available, color: Colors.teal),
                  child: Text(
                    "Availabilities",
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.teal,
                        fontSize: 10
                    ),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.fitness_center, color: Colors.teal),
                  child: Text(
                    "Activities",
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 10
                    ),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.history, color: Colors.teal),
                  child: Text(
                    "Conversation",
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.teal,
                        fontSize: 10
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              renderMeetupLocationView(),
              renderAvailabilitiesView(),
              renderMeetupActivitiesView(),
              renderMeetupCommentsView(),
            ],
          ),
        ),
      );
  }

  bool shouldMeetupBeReadOnly() {
    return (widget.currentMeetup.meetupStatus == "Expired" || widget.currentMeetup.meetupStatus == "Complete");
  }

  _showSnackbarForReadOnlyMeetup() {
    if (widget.currentMeetup.meetupStatus == "Expired") {
      SnackbarUtils.showSnackBarShort(context, "Meetup has expired and cannot be edited");
    }
    else {
      SnackbarUtils.showSnackBarShort(context, "Meetup is complete and cannot be edited");
    }
  }

  Widget renderMeetupCommentsView() {
    return _renderMeetupComments();
  }

  // Must fetch diary entries for all users pertaining to this meeup
  Widget renderMeetupActivitiesView() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _showFilterByDropDown(),
        WidgetUtils.spacer(2.5),
        _renderExerciseDiaryEntries(),
        WidgetUtils.spacer(2.5),
        _renderFoodDiaryEntriesWithContainer(),
      ],
    );
  }

  _showFilterByDropDown() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter by",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14
            ),
          ),
          WidgetUtils.spacer(2.5),
          DropdownButton<String>(
              isExpanded: true,
              value: selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor,
              items: widget.selectedMeetupParticipantUserProfiles.map((e) => DropdownMenuItem<String>(
                value: e.userId,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: CircleAvatar(
                          radius: 15,
                          child: Stack(
                            children: WidgetUtils.skipNulls([
                              Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: ImageUtils.getUserProfileImage(e, 500, 500),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Text(
                        "${e.firstName} ${e.lastName}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.teal,
                        ),
                      )
                    )
                  ],
                ),
              )).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor = newValue;
                  });
                }
              }
          )
        ],
      ),
    );
  }

  _renderExerciseDiaryEntries() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.teal)
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(5),
              child: const Text(
                "Cardio",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),
              ),
            ),
            WidgetUtils.spacer(1),
            _renderCardioDiaryEntries(),
            WidgetUtils.spacer(5),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(5),
              child: const Text(
                "Strength",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),
              ),
            ),
            WidgetUtils.spacer(1),
            _renderStrengthDiaryEntries(),
          ],
        ),
      ),
    );
  }

  _renderCardioDiaryEntries() {
    if (widget.selectedUserProfilesToShowDetailsFor.isNotEmpty) {
      final diaryEntriesForSelectedUser = widget.participantDiaryEntriesMap[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;
      return diaryEntriesForSelectedUser.cardioWorkouts.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: diaryEntriesForSelectedUser.cardioWorkouts.length,
          itemBuilder: (context, index) {
            final currentCardioEntry = diaryEntriesForSelectedUser.cardioWorkouts[index];
            return Dismissible(
              background: WidgetUtils.viewUnderDismissibleListTile(),
              direction: DismissDirection.endToStart,
              key: Key(currentCardioEntry.id),
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  // Now we also have to remove it from the state variable
                  // Remove it when dismissed carefully

                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                    SnackBar(
                        duration: const Duration(milliseconds: 1500),
                        content: const Text("Successfully removed cardio entry!"),
                        action: SnackBarAction(
                            label: "Undo",
                            onPressed: () {
                              // fill this in
                            }) // this is what you needed
                    ),
                  )
                      .closed
                      .then((value) {
                    // Actually remove it here
                  });
                }
              },
              child: InkWell(
                onTap: () {},
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Text(currentCardioEntry.name)
                            )
                        ),
                        Expanded(
                            flex: 1,
                            child: Text(
                              "${currentCardioEntry.durationInMinutes} minutes",
                            )
                        ),
                        Expanded(
                            flex: 1,
                            child: Text(
                              "${currentCardioEntry.caloriesBurned.toInt()} calories",
                              style: const TextStyle(
                                  color: Colors.teal
                              ),
                            )
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
      ) : const Center(
        child: Text("No items here..."),
      );
    }
    else {
      return const Center(
        child: Text("No items here..."),
      );
    }
  }

  _renderStrengthDiaryEntries() {
    if (widget.selectedUserProfilesToShowDetailsFor.isNotEmpty) {
      final diaryEntriesForSelectedUser = widget.participantDiaryEntriesMap[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;
      return diaryEntriesForSelectedUser.strengthWorkouts.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: diaryEntriesForSelectedUser.strengthWorkouts.length,
          itemBuilder: (context, index) {
            final currentStrengthEntry = diaryEntriesForSelectedUser.strengthWorkouts[index];
            return Dismissible(
              background: WidgetUtils.viewUnderDismissibleListTile(),
              key: Key(currentStrengthEntry.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  // Now we also have to remove it from the state variable
                  // fix this here

                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                    SnackBar(
                        duration: const Duration(milliseconds: 1500),
                        content: const Text("Successfully removed workout entry!"),
                        action: SnackBarAction(
                            label: "Undo",
                            onPressed: () {
                              // fix this as well
                            }) // this is what you needed
                    ),
                  )
                      .closed
                      .then((value) {
                    // ACTUALLY remove it here
                  });
                }
              },
              child: InkWell(
                onTap: () {},
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 6,
                            child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Text(currentStrengthEntry.name)
                            )
                        ),
                        Expanded(
                            flex: 3,
                            child: Text("${currentStrengthEntry.sets} sets")
                        ),
                        Expanded(
                            flex: 3,
                            child: Text("${currentStrengthEntry.reps} reps")
                        ),
                        Expanded(
                            flex: 4,
                            child: Text(
                              "${currentStrengthEntry.caloriesBurned.toInt()} calories",
                              style: const TextStyle(
                                  color: Colors.teal
                              ),
                            )
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
      ) : const Center(
        child: Text("No items here..."),
      );
    }
    else {
      return const Center(
        child: Text("No items here..."),
      );
    }

  }

  _renderFoodDiaryEntriesWithContainer() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.teal)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
          // Heading
              Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(5),
              child: const Text(
                "Nutrition",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),
              ),
            ),
            WidgetUtils.spacer(1.5),
            _renderFoodDiaryEntries(),
          ]
        ),
      ),
    );
  }

  _renderFoodDiaryEntries() {
    if (widget.selectedUserProfilesToShowDetailsFor.isNotEmpty) {
      final diaryEntriesForSelectedUser = widget.participantDiaryEntriesMap[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;

      if (diaryEntriesForSelectedUser.foodEntries.isNotEmpty) {
        return ListView.builder(
            shrinkWrap: true,
            itemCount: diaryEntriesForSelectedUser.foodEntries.length,
            itemBuilder: (context, index) {
              final foodEntryForHeadingRaw = diaryEntriesForSelectedUser.foodEntries[index];
              final detailedFoodEntry = widget.rawFoodEntries.firstWhere((element) {
                if (element.isLeft) {
                  return element.left.food.food_id == foodEntryForHeadingRaw.foodId.toString();
                }
                else {
                  return element.right.food.food_id == foodEntryForHeadingRaw.foodId.toString();
                }
              });
              final caloriesRaw = detailedFoodEntry.isLeft ?
              detailedFoodEntry.left.food.servings.serving.firstWhere((element) => element.serving_id == foodEntryForHeadingRaw.servingId.toString()).calories :
              detailedFoodEntry.right.food.servings.serving.calories;

              return Dismissible(
                background: WidgetUtils.viewUnderDismissibleListTile(),
                direction: DismissDirection.endToStart,
                key: Key(foodEntryForHeadingRaw.id),
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    // Now we also have to remove it from the state variable
                    // Ask user for prompt confirming what they want to do here

                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(
                      SnackBar(
                          duration: const Duration(milliseconds: 1500),
                          content: const Text("Successfully removed food entry!"),
                          action: SnackBarAction(
                              label: "Undo",
                              onPressed: () {
                                // fill this in
                              })
                      ),
                    )
                        .closed
                        .then((value) {
                      if (value != SnackBarClosedReason.action) {
                        // Proceed to soft or hard delete over here
                      }
                    });
                  }
                },
                child: InkWell(
                  onTap: () {},
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                          detailedFoodEntry.isLeft ? detailedFoodEntry.left.food.food_name : detailedFoodEntry.right.food.food_name
                                      )
                                  ),
                                  Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        "${foodEntryForHeadingRaw.numberOfServings.toStringAsFixed(2)} servings",
                                        style: const TextStyle(
                                            fontSize: 12
                                        ),
                                      )
                                  ),
                                ],
                              )
                          ),
                          Expanded(
                              flex: 4,
                              child: Text(
                                "${(double.parse(caloriesRaw ?? "0") * foodEntryForHeadingRaw.numberOfServings).toStringAsFixed(0)} calories",
                                style: const TextStyle(
                                    color: Colors.teal
                                ),
                              )
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
        );
      }
      else {
        return const Center(
          child: Text("No items here..."),
        );
      }
    }
    else {
      return const Center(
        child: Text("No items here..."),
      );
    }
  }

  _renderMeetupComments() {
    return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
          maxHeight: 400,
        ),
        child: MeetupCommentsListView.withBloc(
            currentUserId: widget.currentUserProfile.userId,
            meetupId: widget.currentMeetup.id
        )
    );
  }

  Widget renderMeetupLocationView() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _renderMeetupLocation(),
        WidgetUtils.spacer(2.5),
        _renderMeetupFsqLocationCardIfNeeded(),
      ],
    );
  }

  _renderMeetupLocation() {
    return SizedBox(
        height: ScreenUtils.getScreenHeight(context) * 0.25,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MeetupLocationView(
            currentUserProfile: widget.currentUserProfile,
            meetupLocation: widget.selectedMeetupLocation?.toMeetupLocation(),
            userProfiles: widget.selectedMeetupParticipantUserProfiles,
            onTapCallback: () {
              // Go to select location route
              if (widget.currentUserProfile.userId == widget.currentMeetup.ownerId && !shouldMeetupBeReadOnly()) {
                _goToSelectLocationRoute();
              }
              else {
                if (shouldMeetupBeReadOnly()) {
                  _showSnackbarForReadOnlyMeetup();
                }
                else {
                  SnackbarUtils.showSnackBarShort(context, "Cannot modify meetup location unless you are the owner!");
                }
              }
            },
          ),
        )
    );
  }

  _goToSelectLocationRoute() {
    Navigator.push(
        context,
        SearchLocationsView.route(
            userProfilesWithLocations: widget.selectedMeetupParticipantUserProfiles
                .map((e) => UserProfileWithLocation(e, e.locationCenter!.latitude, e.locationCenter!.longitude, e.locationRadius!.toDouble()))
                .toList(),
            initialSelectedLocationId: widget.selectedMeetupLocationId,
            initialSelectedLocationFsqId: widget.selectedMeetupLocationFsqId,
            updateBlocCallback: widget.searchLocationViewUpdateBlocCallback
        ),
    ).then((value) {
      widget.searchLocationViewUpdateMeetupLocationViaBlocCallback();
    });
  }

  // Need an API call to fetch the FSQ result, wait for bloc to complete
  _renderMeetupFsqLocationCardIfNeeded() {
    if (widget.selectedMeetupLocation == null) {
      return Center(
        child: Text(
          "Meetup location unset",
          style: TextStyle(
              color: Theme.of(context).errorColor,
              fontWeight: FontWeight.bold
          ),
        ),
      );
    }
    else {
      return SizedBox(
        height: 270,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: FoursquareLocationCardView(
              locationId: widget.selectedMeetupLocation!.locationId,
              location: widget.selectedMeetupLocation!.location,
            ),
          ),
        ),
      );
    }
  }

  Widget renderAvailabilitiesView() {
    return ListView(
      children: WidgetUtils.skipNulls([
        WidgetUtils.spacer(2.5),
        _renderEditAvailabilitiesButton(),
        _renderHintTextIfNeeded(),
        WidgetUtils.spacer(2.5),
        _renderAvailabilitiesView(),
      ]),
    );
  }

  _renderHintTextIfNeeded() {
    if (widget.isAvailabilitySelectHappening) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WidgetUtils.spacer(2.5),
          const AutoSizeText(
            "Tap on a block to select or unselect it",
            style: TextStyle(
              color: Colors.teal,
              fontSize: 12
            ),
            maxFontSize: 12,
            textAlign: TextAlign.center,
          ),
          WidgetUtils.spacer(2.5),
          const AutoSizeText(
            "Long press on a block to enable multi select",
            style: TextStyle(
                color: Colors.teal,
                fontSize: 12
            ),
            maxFontSize: 12,
            textAlign: TextAlign.center,
          ),
          WidgetUtils.spacer(2.5),
          const AutoSizeText(
            "Drag to the bottom right to select multiple blocks",
            style: TextStyle(
                color: Colors.teal,
                fontSize: 12
            ),
            maxFontSize: 12,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return null;
  }

  _renderEditAvailabilitiesButton() {
    if (widget.isAvailabilitySelectHappening) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: widget.cancelEditAvailabilitiesButtonCallback,
                child: const Text("Cancel edits"),
              ),
            ),
            WidgetUtils.spacer(5),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.saveAvailabilitiesButtonCallback,
                child: const Text("Save edits"),
              ),
            ),
          ],
        ),
      );
    }
    else {
      return Center(
        child: ElevatedButton(
          onPressed: widget.editAvailabilitiesButtonCallback,
          child: const Text("Edit your availability"),
        ),
      );
    }
  }

  _renderAvailabilitiesView() {
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * 0.75,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: DiscreteAvailabilitiesView(
          currentUserAcceptingAvailabilityFor: widget.isAvailabilitySelectHappening ? widget.currentUserProfile.userId : null,
          availabilityChangedCallback: widget.availabilitiesChangedCallback,
          startHour: AddOwnerAvailabilitiesViewState.availabilityStartHour,
          endHour: AddOwnerAvailabilitiesViewState.availabilityEndHour,
          style: TimePlannerStyle(
            // cellHeight: 60,
            // cellWidth: 60,
            showScrollBar: true,
          ),
          headers: _renderAvailabilityHeaders(widget.currentMeetup.createdAt.toLocal()),
          tasks: const [],
          availabilityInitialDay: widget.currentMeetup.createdAt.toLocal(),
          meetupAvailabilities: Map.fromEntries(widget
              .userMeetupAvailabilities
              .entries
              .where((element) =>
              widget.selectedUserProfilesToShowDetailsFor.map((e) => e.userId).contains(element.key))
          ),
        ),
      ),
    );
  }

  _renderAvailabilityHeaders(DateTime initialDay) {
    return List.generate(AddOwnerAvailabilitiesViewState.availabilityDaysAhead, (i) {
      final currentDate = initialDay.add(Duration(days: i));
      return TimePlannerTitle(
        date: DateFormat("MMM-dd").format(currentDate),
        title: DateFormat("EEEE").format(currentDate),
      );
    });
  }

}