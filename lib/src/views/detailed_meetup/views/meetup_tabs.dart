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
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_bloc.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
import 'package:flutter_app/src/views/detailed_meetup/views/meetup_activities_tab.dart';
import 'package:flutter_app/src/views/detailed_meetup/views/meetup_availabilities_tab.dart';
import 'package:flutter_app/src/views/detailed_meetup/views/meetup_location_tab.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/meetup_comments_list.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/select_from_diary_entries_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                tabs: [
                  Tab(
                    icon: const Icon(Icons.location_on, color: Colors.teal,),
                    child: _tabHeader("Location"),
                  ),
                  Tab(
                    icon: const Icon(Icons.event_available, color: Colors.teal,),
                    child: _tabHeader("Availabilities"),
                  ),
                  Tab(
                    icon: const Icon(Icons.fitness_center, color: Colors.teal,),
                    child: _tabHeader("Activities"),
                  ),
                  Tab(
                    icon: const Icon(Icons.history, color: Colors.teal,),
                    child: _tabHeader("Conversation"),
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

  _tabHeader(String heading) => Tab(
    icon: const Icon(Icons.fitness_center, color: Colors.teal),
    child: Text(
      heading,
      maxLines: 1,
      style: const TextStyle(
          color: Colors.teal,
          fontSize: 10
      ),
    ),
  );

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

  Widget renderMeetupCommentsView() {
    return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
          maxHeight: 400,
        ),
        child: MeetupCommentsListView.withBloc(
            currentUserProfile: widget.currentUserProfile,
            meetupId: widget.currentMeetup.id
        )
    );
  }

  Widget renderMeetupActivitiesView() {
    return MeetupActivitiesTab(
        currentUserProfile: widget.currentUserProfile,
        currentMeetup: widget.currentMeetup,
        participantDiaryEntriesMap: participantDiaryEntriesMapState,
        rawFoodEntries: rawFoodEntriesState,
        selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor: selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor,
        selectedMeetupParticipantUserProfiles: widget.selectedMeetupParticipantUserProfiles
    );
  }

  Widget renderMeetupLocationView() {
    return MeetupLocationTab(
        currentUserProfile: widget.currentUserProfile,
        isAvailabilitySelectHappening: widget.isAvailabilitySelectHappening,
        currentMeetup: widget.currentMeetup,
        selectedMeetupParticipantUserProfiles: widget.selectedMeetupParticipantUserProfiles,
        selectedMeetupLocation: widget.selectedMeetupLocation,
        selectedMeetupLocationId: widget.selectedMeetupLocationId,
        selectedMeetupLocationFsqId: widget.selectedMeetupLocationFsqId,
        searchLocationViewUpdateBlocCallback: widget.searchLocationViewUpdateBlocCallback,
        searchLocationViewUpdateMeetupLocationViaBlocCallback: widget.searchLocationViewUpdateMeetupLocationViaBlocCallback
    );
  }

  Widget renderAvailabilitiesView() {
    return MeetupAvailabilitiesTab(
        currentUserProfile: widget.currentUserProfile,
        isAvailabilitySelectHappening: widget.isAvailabilitySelectHappening,
        currentMeetup: widget.currentMeetup,
        userMeetupAvailabilities: widget.userMeetupAvailabilities,
        selectedUserProfilesToShowDetailsFor: widget.selectedUserProfilesToShowDetailsFor,
        availabilitiesChangedCallback: widget.availabilitiesChangedCallback,
        cancelEditAvailabilitiesButtonCallback: widget.cancelEditAvailabilitiesButtonCallback,
        saveAvailabilitiesButtonCallback: widget.saveAvailabilitiesButtonCallback,
        editAvailabilitiesButtonCallback: widget.editAvailabilitiesButtonCallback,
    );
  }

}