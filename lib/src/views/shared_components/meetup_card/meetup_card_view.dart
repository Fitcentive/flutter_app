import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/bloc/meetup_card_bloc.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/bloc/meetup_card_event.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/bloc/meetup_card_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

typedef GoToChatRoomCallback = void Function(String chatRoomId, List<PublicUserProfile> otherUserProfiles);

class MeetupCardView extends StatefulWidget {

  final VoidCallback onCardTapped;
  final GoToChatRoomCallback onChatButtonPressed;

  final PublicUserProfile currentUserProfile;
  final Meetup meetup;
  final MeetupLocation? meetupLocation;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;
  final Map<String, PublicUserProfile> userIdProfileMap;

  static Widget withBloc({
    required PublicUserProfile currentUserProfile,
    required Meetup meetup,
    required MeetupLocation? meetupLocation,
    required List<MeetupParticipant> participants,
    required List<MeetupDecision> decisions,
    required Map<String, PublicUserProfile> userIdProfileMap,
    required VoidCallback onCardTapped,
    required GoToChatRoomCallback onChatButtonPressed,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MeetupCardBloc>(
            create: (context) =>
                MeetupCardBloc(
                  chatRepository: RepositoryProvider.of<ChatRepository>(context),
                  meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )
        ),
      ],
      child: MeetupCardView(
        currentUserProfile: currentUserProfile,
        meetup: meetup,
        meetupLocation: meetupLocation,
        participants: participants,
        decisions: decisions,
        userIdProfileMap: userIdProfileMap,
        onCardTapped: onCardTapped,
        onChatButtonPressed: onChatButtonPressed,
      ),
    );
  }

  const MeetupCardView({
    super.key,
    required this.currentUserProfile,
    required this.meetup,
    this.meetupLocation,
    required this.participants,
    required this.decisions,
    required this.userIdProfileMap,
    required this.onCardTapped,
    required this.onChatButtonPressed,
  });


  @override
  State createState() {
    return MeetupCardViewState();
  }
}

class MeetupCardViewState extends State<MeetupCardView> {

  late final MeetupCardBloc _meetupCardBloc;

  @override
  void initState() {
    super.initState();

    _meetupCardBloc = BlocProvider.of<MeetupCardBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetupCardBloc, MeetupCardState>(
      listener: (context, state) {
        if (state is MeetupChatRoomCreated) {
          final otherUserProfiles = widget.userIdProfileMap.entries
              .map((e) => e.value)
              .where((element) => widget.participants.map((e) => e.userId).contains(element.userId))
              .where((element) => element.userId != widget.currentUserProfile.userId)
              .toList();
          widget.onChatButtonPressed(state.chatRoomId, otherUserProfiles);
        }
      },
      child: _meetupCardItem(
          widget.meetup,
          widget.meetupLocation,
          widget.participants,
          widget.decisions,
          widget.userIdProfileMap,
          context
      ),
    );
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
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetUtils.skipNulls(
                      [
                        _renderTop(meetup),
                        WidgetUtils.spacer(10),
                        _renderBottom(meetup, meetupLocation, participants, decisions, relevantUserProfiles),
                        WidgetUtils.spacer(10),
                        _renderGoToChatRoomButton(),
                      ]
                  ),
                ),
              ),
            )
        ),
      ),
    );
  }

  _renderGoToChatRoomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ElevatedButton.icon(
        icon: const Icon(
            Icons.chat
        ),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          _goToChatRoom();
        },
        label: const Text("Chat", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  // If < 3 - DMs, otherwise meetup group chat (need to create it)
  // Add LISTENER FOR MeetupChatRoomCreated and update it
  _goToChatRoom() {
    if (widget.participants.length < 3) {
      _meetupCardBloc.add(
          GetDirectMessagePrivateChatRoomForMeetup(
              meetup: widget.meetup,
              currentUserProfileId: widget.currentUserProfile.userId,
              participants: widget.participants.map((e) => e.userId).toList()
          )
      );
    }
    else if (widget.meetup.chatRoomId != null) {
      final otherUserProfiles = widget.userIdProfileMap.entries
          .map((e) => e.value)
          .where((element) => widget.participants.map((e) => e.userId).contains(element.userId))
          .where((element) => element.userId != widget.currentUserProfile.userId)
          .toList();
      widget.onChatButtonPressed(widget.meetup.chatRoomId!, otherUserProfiles);
    }
    else {
      _meetupCardBloc.add(
          CreateChatRoomForMeetup(
              meetup: widget.meetup,
              roomName: widget.meetup.name ?? "Unnamed meetup",
              participants: widget.participants.map((e) => e.userId).toList()
          )
      );
    }
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
        child: ParticipantsList(
          participantUserProfiles: userProfiles,
          onParticipantRemoved: null,
          onParticipantTapped: null,
          circleRadius: 45,
          participantDecisions: decisions,
          shouldShowAvailabilityIcon: true,
        ),
      ),
    );
  }


  _renderMapBox(Meetup meetup, MeetupLocation? meetupLocation, List<PublicUserProfile> userProfiles) {
    return SizedBox(
      height: 200,
      child: MeetupLocationView(
        currentUserProfile: widget.currentUserProfile,
        meetupLocation: meetupLocation,
        userProfiles: userProfiles,
        onTapCallback: () {
          // Go to location view?
        },
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
          flex: 3,
          child: Column(
            children: [
              Text(meetup.name ?? "Unnamed meetup", textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ) ,),
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
                    Text(meetup.meetupStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
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