import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_meetup/views/meetup_tabs.dart';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';

class MeetupLocationTab extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  final bool isAvailabilitySelectHappening;
  final Meetup currentMeetup;

  final List<PublicUserProfile> selectedMeetupParticipantUserProfiles;
  final Location? selectedMeetupLocation;
  final String? selectedMeetupLocationId;
  final String? selectedMeetupLocationFsqId;

  final SearchLocationViewUpdateBlocCallback searchLocationViewUpdateBlocCallback;
  final VoidCallback searchLocationViewUpdateMeetupLocationViaBlocCallback;

  const MeetupLocationTab({
    super.key,
    required this.currentUserProfile,

    required this.isAvailabilitySelectHappening,
    required this.currentMeetup,

    required this.selectedMeetupParticipantUserProfiles,
    required this.selectedMeetupLocation,
    required this.selectedMeetupLocationId,
    required this.selectedMeetupLocationFsqId,

    required this.searchLocationViewUpdateBlocCallback,
    required this.searchLocationViewUpdateMeetupLocationViaBlocCallback,
  });

  @override
  State<StatefulWidget> createState() {
    return MeetupLocationTabState();
  }
}

class MeetupLocationTabState extends State<MeetupLocationTab> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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


}