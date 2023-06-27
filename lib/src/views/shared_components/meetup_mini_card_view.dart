import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:intl/intl.dart';

class MeetupMiniCardView extends StatefulWidget {

  final VoidCallback onCardTapped;

  final PublicUserProfile currentUserProfile;
  final Meetup meetup;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;
  final Map<String, PublicUserProfile> userIdProfileMap;


  const MeetupMiniCardView({
    super.key,
    required this.currentUserProfile,
    required this.meetup,
    required this.participants,
    required this.decisions,
    required this.userIdProfileMap,
    required this.onCardTapped,
  });


  @override
  State createState() {
    return MeetupMiniCardViewState();
  }
}

class MeetupMiniCardViewState extends State<MeetupMiniCardView> {


  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return _meetupCardItem(
        widget.meetup,
        widget.participants,
        widget.decisions,
        widget.userIdProfileMap,
        context
    );
  }

  _meetupCardItem(
      Meetup meetup,
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
          widget.onCardTapped();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: WidgetUtils.skipNulls(
                    [
                      _renderTop(meetup),
                      WidgetUtils.spacer(10),
                      _renderBottom(meetup, participants, decisions, relevantUserProfiles),
                    ]
                ),
              ),
            )
        ),
      ),
    );
  }

  _renderBottom(
      Meetup meetup,
      List<MeetupParticipant> participants,
      List<MeetupDecision> decisions,
      List<PublicUserProfile> userProfiles
      ) {
    return _renderParticipantsList(participants, userProfiles, decisions);
  }

  _renderParticipantsList(
      List<MeetupParticipant> participants,
      List<PublicUserProfile> userProfiles,
      List<MeetupDecision> decisions
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: ParticipantsList(
        shouldRenderName: false,
        participantUserProfiles: userProfiles,
        onParticipantRemoved: null,
        onParticipantTapped: null,
        circleRadius: 25,
        participantDecisions: decisions,
        shouldShowAvailabilityIcon: true,
        shouldTapChangeCircleColour: false,
      ),
    );
  }


  _renderTop(Meetup meetup) {
    final meetupDate = meetup.time == null ? "Date unset" : "${DateFormat('EEEE').format(meetup.time!.toLocal())}, ${DateFormat("yyyy-MM-dd").format(meetup.time!.toLocal())}";
    final meetupTime = meetup.time == null ? "Time unset" : DateFormat("hh:mm a").format(meetup.time!.toLocal());
    return Row(
      children: [
        // Name, date and time
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(meetup.name ?? "Unnamed meetup", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, ) ,),
              WidgetUtils.spacer(5),
              Text(meetupTime, style: const TextStyle(fontSize: 9),),
              WidgetUtils.spacer(5),
              Text(meetupDate, style: const TextStyle(fontSize: 9),),
            ],
          ),
        ),
        Expanded(
            flex: 3,
            child: Column(
              children: WidgetUtils.skipNulls([
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Text(meetup.meetupStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),),
                  ],
                ),
                WidgetUtils.spacer(5),
                Wrap(
                  alignment: WrapAlignment.center,
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
    if (meetup.ownerId == widget.currentUserProfile.userId) {
      return const Text(
        "You created this meetup!",
        style: TextStyle(
            fontSize: 9,
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