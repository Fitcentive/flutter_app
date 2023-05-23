import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
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
  final List<PublicUserProfile> selectedUserProfilesToShowAvailabilitiesFor;
  final Meetup currentMeetup;

  final List<PublicUserProfile> selectedMeetupParticipantUserProfiles;
  final Location? selectedMeetupLocation;
  final String? selectedMeetupLocationId;
  final String? selectedMeetupLocationFsqId;

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
    required this.selectedUserProfilesToShowAvailabilitiesFor,
    required this.currentMeetup,

    required this.selectedMeetupParticipantUserProfiles,
    required this.selectedMeetupLocation,
    required this.selectedMeetupLocationId,
    required this.selectedMeetupLocationFsqId,

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
  static const int MAX_TABS = 3;

  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: MAX_TABS);
    _tabController.addListener(() {
      widget.currentSelectedTabCallback(_tabController.index);
    });
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
                    style: TextStyle(
                      color: Colors.teal
                    ),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.event_available, color: Colors.teal),
                  child: Text(
                    "Availabilities",
                    style: TextStyle(
                        color: Colors.teal
                    ),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.history, color: Colors.teal),
                  child: Text(
                    "Activity",
                    style: TextStyle(
                        color: Colors.teal
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
              renderMeetupActivityView(),
            ],
          ),
        ),
      );
  }

  Widget renderMeetupActivityView() {
    return _renderMeetupComments();
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
              if (widget.currentUserProfile.userId == widget.currentMeetup.ownerId) {
                _goToSelectLocationRoute();
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
        height: 275,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _renderEditAvailabilitiesButton(),
        WidgetUtils.spacer(2.5),
        _renderAvailabilitiesView(),
      ],
    );
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              widget.selectedUserProfilesToShowAvailabilitiesFor.map((e) => e.userId).contains(element.key))
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