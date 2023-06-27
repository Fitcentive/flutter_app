import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';

typedef ParticipantRemovedCallback = void Function(PublicUserProfile userProfile);
typedef ParticipantTappedCallback = void Function(PublicUserProfile userProfile, bool isSelected);

class ParticipantsList extends StatefulWidget {
  final List<PublicUserProfile> participantUserProfiles;
  final List<MeetupDecision> participantDecisions;

  final bool shouldShowAvailabilityIcon;
  final bool shouldTapChangeCircleColour;

  final ParticipantRemovedCallback? onParticipantRemoved;
  final ParticipantTappedCallback? onParticipantTapped;

  final double circleRadius;

  final bool shouldRenderName;

  const ParticipantsList({
    super.key,
    required this.participantUserProfiles,
    required this.participantDecisions,
    required this.onParticipantRemoved,
    required this.onParticipantTapped,
    required this.shouldShowAvailabilityIcon,
    required this.shouldTapChangeCircleColour,
    this.circleRadius = 60,
    this.shouldRenderName = true,
  });

  @override
  State createState() {
    return ParticipantsListState();
  }
}

class ParticipantsListState extends State<ParticipantsList> {

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
    return Column(
      children: WidgetUtils.skipNulls([
        CircleAvatar(
          radius: (widget.circleRadius / 2) + ((widget.circleRadius / 2)/10),
          backgroundColor: widget.onParticipantTapped == null ? Colors.teal : (
              isParticipantSelectedMap[userProfile.userId] ?? false ? Colors.teal : Colors.red
          ),
          child: Stack(
            children: WidgetUtils.skipNulls([
              GestureDetector(
                onTap: () {
                  if (widget.shouldTapChangeCircleColour) {
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
              _generateAvailabilitySubscriptIconIfNeeded(userProfile),
            ]),
          ),
        ),
        WidgetUtils.spacer(2),
        // Render name
        widget.shouldRenderName ? Text(
          "${userProfile.firstName} ${userProfile.lastName}",
          style: const TextStyle(
            fontSize: 12,
            color: Colors.teal,
          ),
        ) : null
      ]),
    );
  }

  _generateAvailabilitySubscriptIconIfNeeded(PublicUserProfile userProfile) {
    if (widget.shouldShowAvailabilityIcon) {
      return Align(
        alignment: Alignment.bottomRight,
        child: CircleAvatar(
            radius: widget.circleRadius / 6,
            backgroundColor: _generateBackgroundColour(userProfile),
            child: _generateSubscriptIcon(userProfile)
        ),
      );
    }
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