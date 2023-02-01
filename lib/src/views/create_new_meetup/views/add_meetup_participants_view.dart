import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_participants_list.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMeetupParticipantsView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final List<String> participantUserIds;

  const AddMeetupParticipantsView({
    Key? key,
    required this.currentUserProfile,
    required this.participantUserIds,
  }): super(key: key);

  @override
  State createState() {
    return AddMeetupParticipantsViewState();
  }
}

class AddMeetupParticipantsViewState extends State<AddMeetupParticipantsView> with AutomaticKeepAliveClientMixin {
  late final CreateNewMeetupBloc _createNewMeetupBloc;

  List<String> selectedParticipants = List<String>.empty(growable: true);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _createNewMeetupBloc = BlocProvider.of<CreateNewMeetupBloc>(context);
    selectedParticipants = widget.participantUserIds;
    _updateBlocState(selectedParticipants);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateNewMeetupBloc, CreateNewMeetupState>(
        builder: (context, state) {
          if (state is MeetupModified) {
            return SingleChildScrollView(
              child: Container(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _renderParticipantsView(state),
                      WidgetUtils.spacer(2.5),
                      Divider(color: Theme.of(context).primaryColor),
                      WidgetUtils.spacer(2.5),
                      _renderSearchUserSelectView(state),
                    ],
                  ),
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

  _renderSearchUserSelectView(MeetupModified state) {
    return SelectFromFriendsView.withBloc(
        key: selectFromFriendsViewStateGlobalKey,
        currentUserId: widget.currentUserProfile.userId,
        currentUserProfile: widget.currentUserProfile,
        addSelectedUserIdToParticipantsCallback: _addSelectedUserIdToParticipantsCallback,
        removeSelectedUserIdToParticipantsCallback: _removeSelectedUserIdToParticipantsCallback
    );
  }

  _addSelectedUserIdToParticipantsCallback(String selectedUserId) {
    _updateBlocState({...selectedParticipants, selectedUserId}.toList());
  }

  _removeSelectedUserIdToParticipantsCallback(String selectedUserId) {
    final newParticipants = [...selectedParticipants];
    newParticipants.removeWhere((element) => element == selectedUserId);
    _updateBlocState(newParticipants);
  }


  _onParticipantRemoved(PublicUserProfile removedUser) {
    final updatedListAfterRemovingParticipant = [...selectedParticipants];
    updatedListAfterRemovingParticipant.removeWhere((element) => element == removedUser.userId);
    _updateBlocState(updatedListAfterRemovingParticipant);
    _updateUserSearchResultsListIfNeeded(removedUser.userId);
  }

  _renderParticipantsView(MeetupModified state) {
    if (state.participantUserProfiles.isNotEmpty) {
      return MeetupParticipantsList(
          participantUserProfiles: state.participantUserProfiles,
          onParticipantRemoved: _onParticipantRemoved,
          onParticipantTapped: null,
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