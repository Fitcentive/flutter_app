import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';

typedef MeetupParticipantRemovedCallback = void Function(PublicUserProfile userProfile);
typedef MeetupParticipantTappedCallback = void Function(PublicUserProfile userProfile, bool isSelected);

class MeetupParticipantsList extends StatefulWidget {
  final List<PublicUserProfile> participantUserProfiles;
  final List<MeetupDecision> participantDecisions;

  final MeetupParticipantRemovedCallback? onParticipantRemoved;
  final MeetupParticipantTappedCallback? onParticipantTapped;

  final double circleRadius;

  const MeetupParticipantsList({
    super.key,
    required this.participantUserProfiles,
    required this.participantDecisions,
    required this.onParticipantRemoved,
    required this.onParticipantTapped,
    this.circleRadius = 60,
  });

  @override
  State createState() {
    return MeetupParticipantsListState();
  }
}

class MeetupParticipantsListState extends State<MeetupParticipantsList> {

  Map<String, bool> isParticipantSelectedMap = {};

  @override
  void initState() {
    super.initState();

    widget.participantUserProfiles.forEach((element) {
      isParticipantSelectedMap[element.userId] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: widget.participantUserProfiles.map((e) => _renderParticipantCircleViewWithCloseButton(e)).toList(),
    );
  }

  Widget _renderParticipantCircleViewWithCloseButton(PublicUserProfile userProfile) {
    return CircleAvatar(
      radius: (widget.circleRadius / 2) + ((widget.circleRadius / 2)/10),
      backgroundColor: isParticipantSelectedMap[userProfile.userId] ?? false ? Colors.teal : Colors.red,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onParticipantTapped != null) {
                if (isParticipantSelectedMap[userProfile.userId] ?? false) {
                  setState(() {
                    isParticipantSelectedMap[userProfile.userId] = false;
                  });
                  widget.onParticipantTapped!(userProfile, false);
                }
                else {
                  setState(() {
                    isParticipantSelectedMap[userProfile.userId] = true;
                  });
                  widget.onParticipantTapped!(userProfile, true);
                }

              }
            },
            child: Center(
              child: Container(
                width: widget.circleRadius,
                height: widget.circleRadius,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: ImageUtils.getUserProfileImage(userProfile, 500, 500),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: widget.onParticipantRemoved == null ? null : CircleAvatar(
                radius: widget.circleRadius / 6,
                backgroundColor: Theme.of(context).primaryColor,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onParticipantRemoved != null) {
                      widget.onParticipantRemoved!(userProfile);
                    }
                  },
                  child: Icon(
                    Icons.remove,
                    size: widget.circleRadius / 3,
                    color: Colors.white,
                  ),
                )
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: CircleAvatar(
                radius: widget.circleRadius / 6,
                backgroundColor: _generateBackgroundColour(userProfile),
                child: _generateSubscriptIcon(userProfile)
            ),
          )
        ],
      ),
    );
  }

  _generateSubscriptIcon(PublicUserProfile userProfile) {
    final userDecision = widget.participantDecisions.where((element) => element.userId == userProfile.userId);
    if (userDecision.length == 1) {
      if (userDecision.first.hasAccepted) {
        return Icon(
          Icons.check,
          size: widget.circleRadius / 3,
          color: Colors.white,
        );
      }
      else {
        return Icon(
          Icons.remove,
          size: widget.circleRadius / 3,
          color: Colors.white,
        );
      }
    }
    else {
      return Icon(
        Icons.question_mark,
        size: widget.circleRadius / 3,
        color: Colors.white,
      );
    }
  }

  _generateBackgroundColour(PublicUserProfile userProfile) {
    final userDecision = widget.participantDecisions.where((element) => element.userId == userProfile.userId);
    if (userDecision.length == 1) {
      if (userDecision.first.hasAccepted) {
        return Colors.teal;
      }
      else {
        return Colors.redAccent;
      }
    }
    else {
      return Colors.amber;
    }
  }

}