import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_participants_list.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddOwnerAvailabilitiesView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final List<String> participantUserIds;

  const AddOwnerAvailabilitiesView({
    Key? key,
    required this.currentUserProfile,
    required this.participantUserIds,
  }): super(key: key);

  @override
  State createState() {
    return AddOwnerAvailabilitiesViewState();
  }
}

class AddOwnerAvailabilitiesViewState extends State<AddOwnerAvailabilitiesView> with AutomaticKeepAliveClientMixin {
  static const int availabilityStartHour = 6;
  static const int availabilityEndHour = 23;
  static const int availabilityDaysAhead = 10;

  late final CreateNewMeetupBloc _createNewMeetupBloc;

  List<String> selectedParticipants = List<String>.empty(growable: true);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _createNewMeetupBloc = BlocProvider.of<CreateNewMeetupBloc>(context);
    selectedParticipants = widget.participantUserIds;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateNewMeetupBloc, CreateNewMeetupState>(
        builder: (context, state) {
          if (state is MeetupModified) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _renderParticipantsView(state),
                    WidgetUtils.spacer(5),
                    const Center(child: Text("Tap on a participant to view their availability"),),
                    WidgetUtils.spacer(2.5),
                    Divider(color: Theme.of(context).primaryColor),
                    WidgetUtils.spacer(2.5),
                    _renderUserTextPrompt(),
                    WidgetUtils.spacer(2.5),
                    _renderAvailabilitiesView(state),
                    WidgetUtils.spacer(20),
                  ],
                ),
              ),
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
    );
  }

  _renderUserTextPrompt() {
    return const Center(
      child: Text(
        "Optionally enter your availabilities",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16
        ),
      ),
    );
  }

  _renderAvailabilityHeaders() {
    final now = DateTime.now();
    return List.generate(availabilityDaysAhead, (i) {
      final currentDate = now.add(Duration(days: i));
      return TimePlannerTitle(
        date: DateFormat("MMM-dd").format(currentDate),
        title: DateFormat("EEEE").format(currentDate),
      );
    });
  }

  _availabilityChangedCallback(List<List<bool>> availabilitiesChanged) {
    final currentState = _createNewMeetupBloc.state;
    if (currentState is MeetupModified) {
      _createNewMeetupBloc.add(
          NewMeetupChanged(
              currentUserProfile: currentState.currentUserProfile,
              meetupName: currentState.meetupName,
              meetupTime: currentState.meetupTime,
              location: currentState.location,
              meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
              currentUserAvailabilities: availabilitiesChanged
          )
      );
    }
  }

  _renderAvailabilitiesView(MeetupModified state) {
    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DiscreteAvailabilitiesView(
          currentUserAcceptingAvailabilityFor: widget.currentUserProfile.userId,
          availabilityChangedCallback: _availabilityChangedCallback,
          startHour: availabilityStartHour,
          endHour: availabilityEndHour,
          style: TimePlannerStyle(
            // cellHeight: 60,
            // cellWidth: 60,
            showScrollBar: true,
          ),
          headers: _renderAvailabilityHeaders(),
          tasks: const [],
          availabilityInitialDay: DateTime.now(),
          meetupAvailabilities: const {}, // We don't use tasks, we only use the cells themselves to collect availabilities
        ),
      ),
    );
  }

  _onParticipantRemoved(PublicUserProfile removedUser) {
    final updatedListAfterRemovingParticipant = [...selectedParticipants];
    updatedListAfterRemovingParticipant.removeWhere((element) => element == removedUser.userId);
    _updateBlocState(updatedListAfterRemovingParticipant);
    _updateUserSearchResultsListIfNeeded(removedUser.userId);
  }

  // Update to show only selected user availabilities, instead of current/all user availabilities
  _onParticipantTapped(PublicUserProfile removedUser, bool isSelected) {

  }

  _renderParticipantsView(MeetupModified state) {
    if (state.participantUserProfiles.isNotEmpty) {
      return MeetupParticipantsList(
          participantUserProfiles: state.participantUserProfiles,
          onParticipantRemoved: _onParticipantRemoved,
          onParticipantTapped: _onParticipantTapped,
          participantDecisions: [],
      );
    }
    else {
      return Container(
        constraints: const BoxConstraints(
          minHeight: 60,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Center(
                child: Text("Add participants to meetup..."),
              )
            ],
          ),
        ),
      );
    }
  }

  _updateUserSearchResultsListIfNeeded(String userId) {
    selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(userId);
  }

  _updateBlocState(List<String> participantUserIds) {
    final currentState = _createNewMeetupBloc.state;
    if (currentState is MeetupModified) {
      _createNewMeetupBloc.add(
          NewMeetupChanged(
              currentUserProfile: currentState.currentUserProfile,
              meetupName: currentState.meetupName,
              meetupTime: currentState.meetupTime,
              location: currentState.location,
              meetupParticipantUserIds: participantUserIds,
              currentUserAvailabilities: currentState.currentUserAvailabilities
          )
      );
      setState(() {
        selectedParticipants = participantUserIds;
      });
    }
  }

}