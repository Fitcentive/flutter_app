import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';

typedef MeetupParticipantCallback = void Function(PublicUserProfile userProfile);

class MeetupParticipantsList extends StatefulWidget {
  final List<PublicUserProfile> participantUserProfiles;

  final MeetupParticipantCallback? onParticipantRemoved;
  final MeetupParticipantCallback? onParticipantTapped;

  final double circleRadius;

  const MeetupParticipantsList({
    super.key,
    required this.participantUserProfiles,
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

  Color backgroundColor = Colors.teal;

  @override
  void initState() {
    super.initState();

    widget.participantUserProfiles.forEach((element) {
      isParticipantSelectedMap[element.userId] = false;
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
      backgroundColor: backgroundColor,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onParticipantTapped != null) {
                if (isParticipantSelectedMap[userProfile.userId] ?? false) {
                  setState(() {
                    isParticipantSelectedMap[userProfile.userId] = false;
                    backgroundColor = Colors.teal;
                  });
                }
                else {
                  setState(() {
                    isParticipantSelectedMap[userProfile.userId] = true;
                    backgroundColor = Colors.red;
                  });
                }
                widget.onParticipantTapped!(userProfile);
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
          )
        ],
      ),
    );
  }

}