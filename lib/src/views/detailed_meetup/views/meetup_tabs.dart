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
import 'package:flutter_app/src/views/shared_components/diary_card_view.dart';
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
import 'package:pointer_interceptor/pointer_interceptor.dart';


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

  final VoidCallback scrollToTopCallback;

  final int currentSelectedTab;

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

    required this.scrollToTopCallback,

    required this.currentSelectedTab,
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

    _tabController = TabController(vsync: this, length: MAX_TABS, initialIndex: widget.currentSelectedTab);
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
    if (selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor == widget.currentUserProfile.userId
        && _tabController.index == DetailedMeetupViewState.ACTIVITIES_MEETUP_VIEW_TAB) {
      return  Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: FloatingActionButton(
          heroTag: "MeetupTabsViewAnimatedButton",
          onPressed: () {
            _showDiaryEntrySelectDialog();
          },
          tooltip: 'Associate diary entries to meetup!',
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }
    else if (_tabController.index == DetailedMeetupViewState.CONVERSATION_MEETUP_VIEW_TAB) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Align(
          alignment: const Alignment(0.5, 1.0),
          child: Opacity(
            opacity: 0.66,
            child: FloatingActionButton(
              mini: true,
              heroTag: "MeetupTabsConversationViewAnimatedButton",
              onPressed: () {
                _jumpToTopOfMeetupTabConversationView();
              },
              tooltip: 'Jump to top',
              backgroundColor: Colors.teal,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ),
      );
    }
    else {
      return const Visibility(visible: false, child: CircularProgressIndicator(color: Colors.teal,));
    }
  }

  _jumpToTopOfMeetupTabConversationView() {
    widget.scrollToTopCallback();
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
    return PointerInterceptor(
      child: Scaffold(
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
        bottomNavigationBar: _dismissDialogButton(),
      ),
    );
  }

  _dismissDialogButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          Navigator.pop(context);
        },
        child: const Text("Go back", style: TextStyle(fontSize: 15, color: Colors.white)),
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

  Widget renderMeetupActivitiesView() {
    final diaryEntriesForSelectedUser = participantDiaryEntriesMapState[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 25),
      child: Column(
        // physics: const NeverScrollableScrollPhysics(),
        children: [
          _showFilterByDropDown(),
          WidgetUtils.spacer(2.5),
          Expanded(
            child: DiaryCardView(
                currentUserProfile: widget.currentUserProfile,
                foodDiaryEntries: rawFoodEntriesState,
                allDiaryEntries: diaryEntriesForSelectedUser,
                onCardTapped: () {},
                selectedDate: null,
            ),
          ),
        ],
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

  Widget renderMeetupLocationView() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _renderMeetupLocation(),
          WidgetUtils.spacer(2.5),
          _renderMeetupFsqLocationCardIfNeeded(),
        ],
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
        height: 300,
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
      physics: const NeverScrollableScrollPhysics(),
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