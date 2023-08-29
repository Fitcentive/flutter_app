import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
import 'package:flutter_app/src/views/detailed_meetup/views/meetup_tabs.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:intl/intl.dart';

class MeetupAvailabilitiesTab extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  final bool isAvailabilitySelectHappening;

  final Meetup currentMeetup;
  final Map<String, List<MeetupAvailabilityUpsert>> userMeetupAvailabilities;
  final AvailabilitiesChangedCallback availabilitiesChangedCallback;
  final List<PublicUserProfile> selectedUserProfilesToShowDetailsFor;

  final VoidCallback cancelEditAvailabilitiesButtonCallback;
  final VoidCallback saveAvailabilitiesButtonCallback;
  final VoidCallback editAvailabilitiesButtonCallback;

  const MeetupAvailabilitiesTab({
    super.key,
    required this.currentUserProfile,

    required this.isAvailabilitySelectHappening,

    required this.currentMeetup,
    required this.userMeetupAvailabilities,
    required this.selectedUserProfilesToShowDetailsFor,
    required this.availabilitiesChangedCallback,

    required this.cancelEditAvailabilitiesButtonCallback,
    required this.saveAvailabilitiesButtonCallback,
    required this.editAvailabilitiesButtonCallback,
  });

  @override
  State<StatefulWidget> createState() {
    return MeetupAvailabilitiesTabState();
  }
}

class MeetupAvailabilitiesTabState extends State<MeetupAvailabilitiesTab> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
    _renderAvailabilityHeaders(DateTime initialDay) {
      return List.generate(AddOwnerAvailabilitiesViewState.availabilityDaysAhead, (i) {
        final currentDate = initialDay.add(Duration(days: i));
        return TimePlannerTitle(
          date: DateFormat("MMM-dd").format(currentDate),
          title: DateFormat("EEEE").format(currentDate),
        );
      });
    }

    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * 0.625,
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

}