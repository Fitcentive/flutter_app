import 'dart:async';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SelectMeetupDetailsView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final List<String> participantUserIds;

  const SelectMeetupDetailsView({
    Key? key,
    required this.currentUserProfile,
    required this.participantUserIds,
  }): super(key: key);

  @override
  State createState() {
    return SelectMeetupDetailsViewState();
  }
}

class SelectMeetupDetailsViewState extends State<SelectMeetupDetailsView> with AutomaticKeepAliveClientMixin {
  final String customSelectedLocationMarkerId = "customSelectedLocationMarkerId";

  late final CreateNewMeetupBloc _createNewMeetupBloc;

  DateTime earliestPossibleMeetupDateTime = DateTime.now().add(const Duration(hours: 3));

  List<String> selectedParticipants = List<String>.empty(growable: true);
  late DateTime selectedMeetupDate;

  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _createNewMeetupBloc = BlocProvider.of<CreateNewMeetupBloc>(context);

    selectedParticipants = widget.participantUserIds;

    final currentState = _createNewMeetupBloc.state;
    if (currentState is MeetupModified) {
      selectedMeetupDate = currentState.meetupTime ?? earliestPossibleMeetupDateTime;
    }

  }


  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<CreateNewMeetupBloc, CreateNewMeetupState>(
        builder: (context, state) {
          if (state is MeetupModified) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetUtils.skipNulls([
                    _renderParticipantsView(state),
                    WidgetUtils.spacer(2.5),
                    Divider(color: Theme.of(context).primaryColor),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupNameView(state),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupDateTime(state),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupLocation(state),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupFsqLocationCardIfNeeded(state),
                    // Move this to its own widget
                    // _renderAvailabilitiesView(state),
                  ]),
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


  _renderMeetupFsqLocationCardIfNeeded(MeetupModified state) {
    if (state.location == null) {
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
      // Show the location card view here
      return IntrinsicHeight(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: FoursquareLocationCardView(
              locationId: state.location!.locationId,
              location: state.location!.location,
            ),
          ),
        ),
      );
    }
  }

  _goToSelectLocationRoute(MeetupModified state, BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context,
        SearchLocationsView.route(
            userProfilesWithLocations: [...state.participantUserProfiles, widget.currentUserProfile]
                .map((e) => UserProfileWithLocation(e, e.locationCenter!.latitude, e.locationCenter!.longitude, e.locationRadius!.toDouble()))
                .toList(),
            initialSelectedLocationId: state.location?.locationId,
            initialSelectedLocationFsqId: state.location?.location.fsqId,
            updateBlocCallback: _updateBlocCallback
        ),
            (route) => true
    );
  }

  _updateBlocCallback(Location location) {
    final currentState = _createNewMeetupBloc.state;
    if(currentState is MeetupModified) {
      _createNewMeetupBloc.add(
          NewMeetupChanged(
            currentUserProfile: currentState.currentUserProfile,
            meetupName: currentState.meetupName,
            meetupTime: selectedMeetupDate,
            location: location,
            meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
            currentUserAvailabilities: currentState.currentUserAvailabilities,
          )
      );
    }
  }

  _renderMeetupLocation(MeetupModified state) {
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * 0.25,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MeetupLocationView(
            currentUserProfile: widget.currentUserProfile,
            meetupLocation: state.location?.toMeetupLocation(),
            userProfiles: [...state.participantUserProfiles, widget.currentUserProfile],
            onTapCallback: () {
              _goToSelectLocationRoute(state, context);
            },
          ),
      )
    );
  }

  _renderMeetupNameView(MeetupModified state) {
    return Column(
      children: [
        const Text("Meetup name", style: TextStyle(fontSize: 16),),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onChanged: (text) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                final currentState = _createNewMeetupBloc.state;
                if(currentState is MeetupModified) {
                  _createNewMeetupBloc.add(
                      NewMeetupChanged(
                        currentUserProfile: currentState.currentUserProfile,
                        meetupName: text,
                        meetupTime: currentState.meetupTime,
                        location: currentState.location,
                        meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
                        currentUserAvailabilities: currentState.currentUserAvailabilities,
                      )
                  );
                }
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter meetup name',
              hintStyle: TextStyle(
                fontWeight: FontWeight.normal
              )
            ),
          ),
        )
      ],
    );
  }

  _renderMeetupDateTime(MeetupModified state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: _datePickerButton(state)),
          WidgetUtils.spacer(5),
          Expanded(child: _timePickerButton(state)),
        ],
      ),
    );
  }

  Widget _timePickerButton(MeetupModified state) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        final selectedTime = await showTimePicker(
          initialTime: TimeOfDay.now(),
          builder: (BuildContext context, Widget? child) {
            return Theme(
                data: ThemeData(primarySwatch: Colors.teal),
                child: child!
            );
          },
          context: context,
        );

        final currentState = _createNewMeetupBloc.state;
        if(currentState is MeetupModified && selectedTime != null) {
          setState(() {
            selectedMeetupDate = DateTime(
              selectedMeetupDate.year,
              selectedMeetupDate.month,
              selectedMeetupDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            _createNewMeetupBloc.add(
                NewMeetupChanged(
                  currentUserProfile: currentState.currentUserProfile,
                  meetupName: currentState.meetupName,
                  meetupTime: selectedMeetupDate,
                  location: currentState.location,
                  meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
                  currentUserAvailabilities: currentState.currentUserAvailabilities,
                )
            );
          });
        }
      },
      child: Text(
          DateFormat("hh:mm a").format(selectedMeetupDate),
          style: const TextStyle(
              fontSize: 16,
              color: Colors.white
          )),
    );
  }

  Widget _datePickerButton(MeetupModified state) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        final selectedDate = await showDatePicker(
          builder: (BuildContext context, Widget? child) {
            return Theme(
                data: ThemeData(primarySwatch: Colors.teal),
                child: child!
            );
          },
          context: context,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          initialDate: selectedMeetupDate,
          firstDate: earliestPossibleMeetupDateTime,
          lastDate: DateTime(ConstantUtils.LATEST_YEAR),
        );

        final currentState = _createNewMeetupBloc.state;
        if(currentState is MeetupModified && selectedDate != null) {
          _createNewMeetupBloc.add(
              NewMeetupChanged(
                  currentUserProfile: currentState.currentUserProfile,
                  meetupName: currentState.meetupName,
                  meetupTime: selectedDate,
                  location: currentState.location,
                  meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
                  currentUserAvailabilities: currentState.currentUserAvailabilities,
              )
          );

          setState(() {
            selectedMeetupDate = selectedDate;
          });
        }
      },
      child: Text(
          DateFormat('yyyy-MM-dd').format(selectedMeetupDate),
          style: const TextStyle(
              fontSize: 16,
              color: Colors.white
          )),
    );
  }

  _onParticipantRemoved(PublicUserProfile removedUser) {
    final updatedListAfterRemovingParticipant = [...selectedParticipants];
    updatedListAfterRemovingParticipant.removeWhere((element) => element == removedUser.userId);
    _updateBlocState(updatedListAfterRemovingParticipant);
    _updateUserSearchResultsListIfNeeded(removedUser.userId);
  }

  _renderParticipantsView(MeetupModified state) {
    if (state.participantUserProfiles.isNotEmpty) {
      return ParticipantsList(
          participantUserProfiles: state.participantUserProfiles,
          onParticipantRemoved: _onParticipantRemoved,
          onParticipantTapped: null,
          participantDecisions: [],
          shouldShowAvailabilityIcon: true,
      );
    }
    else {
      return Container(
        constraints: const BoxConstraints(
          minHeight: 50,
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