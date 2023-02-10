import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_participants_list.dart';
import 'package:intl/intl.dart';

class MeetupCardView extends StatelessWidget {

  final VoidCallback onCardTapped;

  final PublicUserProfile currentUserProfile;
  final Meetup meetup;
  final MeetupLocation? meetupLocation;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;
  final Map<String, PublicUserProfile> userIdProfileMap;


  const MeetupCardView({
    super.key,
    required this.currentUserProfile,
    required this.meetup,
    this.meetupLocation,
    required this.participants,
    required this.decisions,
    required this.userIdProfileMap,
    required this.onCardTapped
  });

  @override
  Widget build(BuildContext context) {
    return _meetupCardItem(meetup, meetupLocation, participants, decisions, userIdProfileMap, context);
  }

  _meetupCardItem(
      Meetup meetup,
      MeetupLocation? meetupLocation,
      List<MeetupParticipant> participants,
      List<MeetupDecision> decisions,
      Map<String, PublicUserProfile> userIdProfileMap,
      BuildContext context,
      ) {
    final relevantUserProfiles =
      userIdProfileMap.values.where((element) => participants.map((e) => e.userId).contains(element.userId)).toList();
    return IntrinsicHeight(
      child: GestureDetector(
        onTap: () {
          // _goToEditMeetupView(meetup, meetupLocation, participants, decisions, relevantUserProfiles);
          onCardTapped();
        },
        child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1
                )
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetUtils.skipNulls(
                      [
                        _renderTop(meetup),
                        WidgetUtils.spacer(10),
                        _renderBottom(meetup, meetupLocation, participants, decisions, relevantUserProfiles),
                      ]
                  ),
                ),
              ),
            )
        ),
      ),
    );
  }

  _renderBottom(
      Meetup meetup,
      MeetupLocation? meetupLocation,
      List<MeetupParticipant> participants,
      List<MeetupDecision> decisions,
      List<PublicUserProfile> userProfiles
      ) {
    return Row(
      children: [
        // This part is supposed to be locations view
        Expanded(
          flex: 3,
          child: _renderMapBox(meetup, meetupLocation, userProfiles),
        ),
        // This part is supposed to be participant list
        Expanded(
            flex: 2,
            child: _renderParticipantsList(participants, userProfiles, decisions)
        )
      ],
    );
  }

  _renderParticipantsList(
      List<MeetupParticipant> participants,
      List<PublicUserProfile> userProfiles,
      List<MeetupDecision> decisions
      ) {
    return SizedBox(
      height: 200,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
        child: MeetupParticipantsList(
          participantUserProfiles: userProfiles,
          onParticipantRemoved: null,
          onParticipantTapped: null,
          circleRadius: 45,
          participantDecisions: decisions,
        ),
      ),
    );
  }


  _renderMapBox(Meetup meetup, MeetupLocation? meetupLocation, List<PublicUserProfile> userProfiles) {
    return SizedBox(
      height: 200,
      child: MeetupLocationView(
        currentUserProfile: currentUserProfile,
        meetupLocation: meetupLocation,
        userProfiles: userProfiles,
        onTapCallback: () {
          // Go to location view?
        },
      ),
    );
  }

  _renderTop(Meetup meetup) {
    final meetupDate = meetup.time == null ? "Date unset" : "${DateFormat('EEEE').format(meetup.time!)}, ${DateFormat("yyyy-MM-dd").format(meetup.time!)}";
    final meetupTime = meetup.time == null ? "Time unset" : DateFormat("hh:mm a").format(meetup.time!);
    return Row(
      children: [
        // Name, date and time
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Text(meetup.name ?? "Unnamed meetup", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ),),
              WidgetUtils.spacer(5),
              Text(meetupTime, style: const TextStyle(fontSize: 16),),
              WidgetUtils.spacer(5),
              Text(meetupDate, style: const TextStyle(fontSize: 16),),
            ],
          ),
        ),
        Expanded(
            flex: 2,
            child: Column(
              children: WidgetUtils.skipNulls([
                Row(
                  children: [
                    Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: BoxDecoration(
                        color: ColorUtils.meetupStatusToColorMap[meetup.meetupStatus]!,
                        shape: BoxShape.circle,
                      ),
                    ),
                    WidgetUtils.spacer(5),
                    Text(meetup.meetupStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ],
                ),
                WidgetUtils.spacer(5),
                Wrap(
                  children: WidgetUtils.skipNulls([
                    _showMeetupOwnerIfNeeded(meetup)
                  ]),
                )
              ]) ,
            )
        )
      ],
    );
  }

  Widget? _showMeetupOwnerIfNeeded(Meetup meetup) {
    if (meetup.ownerId == currentUserProfile.userId) {
      return const Text(
        "You created this meetup!",
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.teal
        ),
      );
    }
    else {
      return null;
    }
  }
}