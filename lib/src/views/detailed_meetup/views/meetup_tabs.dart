import 'package:auto_size_text/auto_size_text.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
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
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_bloc.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/meetup_comments_list.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/select_from_diary_entries_view.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late DetailedMeetupBloc _detailedMeetupBloc;

  List<Either<FoodGetResult, FoodGetResultSingleServing>> rawFoodEntriesState = [];
  Map<String, AllDiaryEntries> participantDiaryEntriesMapState = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _detailedMeetupBloc = BlocProvider.of<DetailedMeetupBloc>(context);

    _tabController = TabController(vsync: this, length: MAX_TABS);
    _tabController.addListener(() {
      widget.currentSelectedTabCallback(_tabController.index);
    });

    selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor = widget.currentUserProfile.userId;
    participantDiaryEntriesMapState = widget.participantDiaryEntriesMap;
    rawFoodEntriesState = widget.rawFoodEntries;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Diary Entries", style: TextStyle(color: Colors.teal)),
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      body: DefaultTabController(
          length: MAX_TABS,
          child: Scaffold(
            floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
            floatingActionButton: _animatedButton(),
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
        ),
    );
  }

  _animatedButton() {
    return Visibility(
      visible: selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor == widget.currentUserProfile.userId,
      child: FloatingActionButton(
        heroTag: "MeetupTabsViewAnimatedButton",
        onPressed: () {
          _showDiaryEntrySelectDialog();
        },
        tooltip: 'Share your thoughts!',
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  _showDiaryEntrySelectDialog() {
    showDialog(context: context, builder: (context) {
      return Dialog(
        child: _generateSelectFromDiaryEntriesView(),
      );
    }).then((value) => _detailedMeetupBloc.add(
        SaveAllDiaryEntriesAssociatedWithMeetup(
         currentUserId: widget.currentUserProfile.userId,
         meetupId: widget.currentMeetup.id,
         cardioDiaryEntryIds: participantDiaryEntriesMapState[widget.currentUserProfile.userId]!.cardioWorkouts.map((e) => e.id).toList(),
         strengthDiaryEntryIds: participantDiaryEntriesMapState[widget.currentUserProfile.userId]!.strengthWorkouts.map((e) => e.id).toList(),
         foodDiaryEntryIds: participantDiaryEntriesMapState[widget.currentUserProfile.userId]!.foodEntries.map((e) => e.id).toList(),
        )
    ));
  }

  _generateSelectFromDiaryEntriesView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Diary Entries', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: SelectFromDiaryEntriesView.withBloc(
        currentUserProfile: widget.currentUserProfile,
          previouslySelectedCardioDiaryEntryIds: participantDiaryEntriesMapState[widget.currentUserProfile.userId]!.cardioWorkouts.map((e) => e.id).toList(),
          previouslySelectedStrengthDiaryEntryIds: participantDiaryEntriesMapState[widget.currentUserProfile.userId]!.strengthWorkouts.map((e) => e.id).toList(),
          previouslySelectedFoodDiaryEntryIds: participantDiaryEntriesMapState[widget.currentUserProfile.userId]!.foodEntries.map((e) => e.id).toList(),
          updateSelectedCardioDiaryEntryIdCallback: _updateSelectedCardioDiaryEntryIdCallback,
          updateSelectedStrengthDiaryEntryIdCallback: _updateSelectedStrengthDiaryEntryIdCallback,
          updateSelectedFoodDiaryEntryIdCallback: _updateSelectedFoodDiaryEntryIdCallback,
      ),
    );
  }

  void _updateSelectedCardioDiaryEntryIdCallback(CardioDiaryEntry cardioInfo, bool isSelected) {
    if (isSelected) {
      final currentEntries = participantDiaryEntriesMapState[widget.currentUserProfile.userId]!;
      final newDiaryEntries = AllDiaryEntries(
          List.from(currentEntries.cardioWorkouts)..add(cardioInfo),
          currentEntries.strengthWorkouts,
          currentEntries.foodEntries,
      );
      setState(() {
        participantDiaryEntriesMapState[widget.currentUserProfile.userId] = newDiaryEntries;
      });
    }
    else {
      final currentEntries = participantDiaryEntriesMapState[widget.currentUserProfile.userId]!;
      final newDiaryEntries = AllDiaryEntries(
        List.from(currentEntries.cardioWorkouts.where((element) => element.id != cardioInfo.id)),
        currentEntries.strengthWorkouts,
        currentEntries.foodEntries,
      );
      setState(() {
        participantDiaryEntriesMapState[widget.currentUserProfile.userId] = newDiaryEntries;
      });
    }
  }

  void _updateSelectedStrengthDiaryEntryIdCallback(StrengthDiaryEntry info, bool isSelected) {
    if (isSelected) {
      final currentEntries = participantDiaryEntriesMapState[widget.currentUserProfile.userId]!;
      final newDiaryEntries = AllDiaryEntries(
        currentEntries.cardioWorkouts,
        List.from(currentEntries.strengthWorkouts)..add(info),
        currentEntries.foodEntries,
      );
      setState(() {
        participantDiaryEntriesMapState[widget.currentUserProfile.userId] = newDiaryEntries;
      });
    }
    else {
      final currentEntries = participantDiaryEntriesMapState[widget.currentUserProfile.userId]!;
      final newDiaryEntries = AllDiaryEntries(
        currentEntries.cardioWorkouts,
        List.from(currentEntries.strengthWorkouts.where((element) => element.id != info.id)),
        currentEntries.foodEntries,
      );
      setState(() {
        participantDiaryEntriesMapState[widget.currentUserProfile.userId] = newDiaryEntries;
      });
    }
  }

  void _updateSelectedFoodDiaryEntryIdCallback(
      FoodDiaryEntry info,
      Either<FoodGetResult, FoodGetResultSingleServing> infoRaw,
      bool isSelected,
      ) {
    if (isSelected) {
      final currentEntries = participantDiaryEntriesMapState[widget.currentUserProfile.userId]!;
      final newDiaryEntries = AllDiaryEntries(
        currentEntries.cardioWorkouts,
        currentEntries.strengthWorkouts,
        List.from(currentEntries.foodEntries)..add(info),
      );
      setState(() {
        participantDiaryEntriesMapState[widget.currentUserProfile.userId] = newDiaryEntries;
        rawFoodEntriesState = List.from(rawFoodEntriesState)..add(infoRaw);
      });
    }
    else {
      final currentEntries = participantDiaryEntriesMapState[widget.currentUserProfile.userId]!;
      final newDiaryEntries = AllDiaryEntries(
        currentEntries.cardioWorkouts,
        currentEntries.strengthWorkouts,
        List.from(currentEntries.foodEntries.where((element) => element.id != info.id)),
      );
      setState(() {
        participantDiaryEntriesMapState[widget.currentUserProfile.userId] = newDiaryEntries;
      });
    }
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
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _showFilterByDropDown(),
              WidgetUtils.spacer(2.5),
              _renderExerciseDiaryEntries(),
              WidgetUtils.spacer(2.5),
              _renderFoodDiaryEntriesWithContainer(),
            ],
          ),
        ),
      ),
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
      final diaryEntriesForSelectedUser = participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;
      return diaryEntriesForSelectedUser.cardioWorkouts.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: diaryEntriesForSelectedUser.cardioWorkouts.length,
          itemBuilder: (context, index) {
            final currentCardioEntry = diaryEntriesForSelectedUser.cardioWorkouts[index];
            return Dismissible(
              background: WidgetUtils.viewUnderDismissibleListTile(),
              direction: DismissDirection.endToStart,
              key: Key(currentCardioEntry.id),
              confirmDismiss: (direction) {
                if (widget.currentUserProfile.userId == currentCardioEntry.userId) {
                  return Future.value(true);
                }
                else {
                  SnackbarUtils.showSnackBarShort(
                      context,
                      "Cannot remove another user's associated activities!"
                  );
                  return Future.value(false);
                }

              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  // Now we also have to remove it from the state variable
                  // Remove it when dismissed carefully
                  setState(() {
                    final newDiaryEntriesForSelectedUser = AllDiaryEntries(
                        diaryEntriesForSelectedUser.cardioWorkouts.where((element) => element.id != currentCardioEntry.id).toList(),
                        diaryEntriesForSelectedUser.strengthWorkouts,
                        diaryEntriesForSelectedUser.foodEntries
                    );
                    participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor] = newDiaryEntriesForSelectedUser;
                  });

                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                    SnackBar(
                        duration: const Duration(milliseconds: 1500),
                        content: const Text("Successfully removed cardio entry!"),
                        action: SnackBarAction(
                            label: "Undo",
                            onPressed: () {
                              setState(() {
                                participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor] = diaryEntriesForSelectedUser;
                              });
                            }) // this is what you needed
                    ),
                  )
                      .closed
                      .then((value) {
                          if (value != SnackBarClosedReason.action) {
                            // Actually remove it now. Removing only means disassociating it from meetup not deleting underlying diary entry
                            _detailedMeetupBloc.add(
                                DissociateCardioDiaryEntryFromMeetup(
                                    meetupId: widget.currentMeetup.id,
                                    currentUserId: widget.currentUserProfile.userId,
                                    cardioDiaryEntryId: currentCardioEntry.id
                                )
                            );
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
      final diaryEntriesForSelectedUser = participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;
      return diaryEntriesForSelectedUser.strengthWorkouts.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: diaryEntriesForSelectedUser.strengthWorkouts.length,
          itemBuilder: (context, index) {
            final currentStrengthEntry = diaryEntriesForSelectedUser.strengthWorkouts[index];
            return Dismissible(
              background: WidgetUtils.viewUnderDismissibleListTile(),
              key: Key(currentStrengthEntry.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) {
                if (widget.currentUserProfile.userId == currentStrengthEntry.userId) {
                  return Future.value(true);
                }
                else {
                  SnackbarUtils.showSnackBarShort(
                      context,
                      "Cannot remove another user's associated activities!"
                  );
                  return Future.value(false);
                }

              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  // Now we also have to remove it from the state variable
                  setState(() {
                    final newDiaryEntriesForSelectedUser = AllDiaryEntries(
                        diaryEntriesForSelectedUser.cardioWorkouts,
                        diaryEntriesForSelectedUser.strengthWorkouts.where((element) => element.id != currentStrengthEntry.id).toList(),
                        diaryEntriesForSelectedUser.foodEntries
                    );
                    participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor] = newDiaryEntriesForSelectedUser;
                  });

                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                    SnackBar(
                        duration: const Duration(milliseconds: 1500),
                        content: const Text("Successfully removed workout entry!"),
                        action: SnackBarAction(
                            label: "Undo",
                            onPressed: () {
                              setState(() {
                                participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor] = diaryEntriesForSelectedUser;
                              });
                            }) // this is what you needed
                    ),
                  )
                      .closed
                      .then((value) {
                        if (value != SnackBarClosedReason.action) {
                          // Actually remove it now. Removing only means disassociating it from meetup not deleting underlying diary entry
                          _detailedMeetupBloc.add(
                              DissociateStrengthDiaryEntryFromMeetup(
                                  meetupId: widget.currentMeetup.id,
                                  currentUserId: widget.currentUserProfile.userId,
                                  strengthDiaryEntryId: currentStrengthEntry.id
                              )
                            );
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
      final diaryEntriesForSelectedUser = participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;

      if (diaryEntriesForSelectedUser.foodEntries.isNotEmpty) {
        return ListView.builder(
            shrinkWrap: true,
            itemCount: diaryEntriesForSelectedUser.foodEntries.length,
            itemBuilder: (context, index) {
              final foodEntryForHeadingRaw = diaryEntriesForSelectedUser.foodEntries[index];
              final detailedFoodEntry = rawFoodEntriesState.firstWhere((element) {
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
                confirmDismiss: (direction) {
                  if (widget.currentUserProfile.userId == foodEntryForHeadingRaw.userId) {
                    return Future.value(true);
                  }
                  else {
                    SnackbarUtils.showSnackBarShort(
                        context,
                        "Cannot modify another user's data!"
                    );
                    return Future.value(false);
                  }

                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    // Now we also have to remove it from the state variable
                    setState(() {
                      final newDiaryEntriesForSelectedUser = AllDiaryEntries(
                          diaryEntriesForSelectedUser.cardioWorkouts,
                          diaryEntriesForSelectedUser.strengthWorkouts,
                          diaryEntriesForSelectedUser.foodEntries.where((element) => element.id != foodEntryForHeadingRaw.id).toList(),
                      );
                      participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor] = newDiaryEntriesForSelectedUser;
                    });

                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(
                      SnackBar(
                          duration: const Duration(milliseconds: 1500),
                          content: const Text("Successfully removed food entry!"),
                          action: SnackBarAction(
                              label: "Undo",
                              onPressed: () {
                                setState(() {
                                  participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor] = diaryEntriesForSelectedUser;
                                });
                              })
                      ),
                    )
                        .closed
                        .then((value) {
                      if (value != SnackBarClosedReason.action) {
                        // Actually remove it now. Removing only means disassociating it from meetup not deleting underlying diary entry
                        _detailedMeetupBloc.add(
                            DissociateFoodDiaryEntryFromMeetup(
                                meetupId: widget.currentMeetup.id,
                                currentUserId: widget.currentUserProfile.userId,
                                foodDiaryEntryId: foodEntryForHeadingRaw.id
                            )
                        );
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
    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _renderMeetupLocation(),
            WidgetUtils.spacer(2.5),
            _renderMeetupFsqLocationCardIfNeeded(),
          ],
        ),
      ),
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