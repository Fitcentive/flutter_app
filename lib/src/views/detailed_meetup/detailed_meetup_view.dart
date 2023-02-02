import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_bloc.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_participants_list.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DetailedMeetupView extends StatefulWidget {
  final Meetup meetup;
  final MeetupLocation? meetupLocation;
  final List<MeetupParticipant> participants;
  final List<MeetupDecision> decisions;
  final List<PublicUserProfile> userProfiles;

  const DetailedMeetupView({
    super.key,
    required this.meetup,
    this.meetupLocation,
    required this.participants,
    required this.decisions,
    required this.userProfiles
  });

  static Widget withBloc(
    Meetup meetup,
    MeetupLocation? meetupLocation,
    List<MeetupParticipant> participants,
    List<MeetupDecision> decisions,
    List<PublicUserProfile> userProfiles,
  ) => MultiBlocProvider(
    providers: [
      BlocProvider<DetailedMeetupBloc>(
          create: (context) => DetailedMeetupBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: DetailedMeetupView(
        meetup: meetup,
        participants: participants,
        decisions: decisions,
        userProfiles: userProfiles,
        meetupLocation: meetupLocation,
    ),
  );

  @override
  State createState() {
    return DetailedMeetupViewState();
  }
}

class DetailedMeetupViewState extends State<DetailedMeetupView> {
  late DetailedMeetupBloc _detailedMeetupBloc;

  Timer? _debounce;

  DateTime earliestPossibleMeetupDateTime = DateTime.now().add(const Duration(hours: 3));

  List<String> selectedParticipants = List<String>.empty(growable: true);
  late DateTime selectedMeetupDate;

  @override
  void initState() {
    super.initState();

    selectedMeetupDate = widget.meetup.time ?? earliestPossibleMeetupDateTime;

    _detailedMeetupBloc = BlocProvider.of<DetailedMeetupBloc>(context);
    _detailedMeetupBloc.add(FetchAdditionalMeetupData(
      meetupId: widget.meetup.id,
      participantIds: widget.participants.map((e) => e.userId).toList()
    ));
  }

  // todo - need to be able to add/edit availabilities as a user/participant
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Meetup", style: TextStyle(color: Colors.teal)),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: BlocBuilder<DetailedMeetupBloc, DetailedMeetupState>(
        builder: (context, state) {
          if (state is DetailedMeetupDataFetched) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetUtils.skipNulls([
                    _renderParticipantsView(),
                    WidgetUtils.spacer(2.5),
                    Divider(color: Theme.of(context).primaryColor),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupNameView(),
                    _renderMeetupDateTime(),
                    _renderMeetupLocation(),
                    WidgetUtils.spacer(2.5),
                    // _renderMeetupFsqLocationCardIfNeeded(),
                    _renderAvailabilitiesView(state.userAvailabilities),
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
        },
      ),
    );
  }

  _renderAvailabilityHeaders() {
    final now = DateTime.now();
    return List.generate(AddOwnerAvailabilitiesViewState.availabilityDaysAhead, (i) {
      final currentDate = now.add(Duration(days: i));
      return TimePlannerTitle(
        date: DateFormat("MMM-dd").format(currentDate),
        title: DateFormat("EEEE").format(currentDate),
      );
    });
  }

  _availabilityChangedCallback(List<List<bool>> availabilitiesChanged) {
    // do smthg
  }

  _renderAvailabilitiesView(Map<String, List<MeetupAvailability>> meetupAvailabilities) {
    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DiscreteAvailabilitiesView(
          availabilityChangedCallback: _availabilityChangedCallback,
          startHour: AddOwnerAvailabilitiesViewState.availabilityStartHour,
          endHour: AddOwnerAvailabilitiesViewState.availabilityEndHour,
          style: TimePlannerStyle(
            // cellHeight: 60,
            // cellWidth: 60,
            showScrollBar: true,
          ),
          headers: _renderAvailabilityHeaders(),
          tasks: const [],
          availabilityInitialDay: widget.meetup.createdAt,
          meetupAvailabilities: meetupAvailabilities,
        ),
      ),
    );
  }

  // Need an API call to fetch the FSQ result, wait for bloc to complete
  _renderMeetupFsqLocationCardIfNeeded() {
    if (widget.meetupLocation == null) {
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
      // return IntrinsicHeight(
      //   child: Center(
      //     child: Container(
      //       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      //       child: FoursquareLocationCardView(
      //         locationId: widget.meetupLocation!.id,
      //         location: null,
      //       ),
      //     ),
      //   ),
      // );
    }
  }

  _renderMeetupLocation() {
    return SizedBox(
        height: ScreenUtils.getScreenHeight(context) * 0.25,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MeetupLocationView(
            meetupLocation: widget.meetupLocation,
            userProfiles: widget.userProfiles,
            onTapCallback: () {
              // Go to select location
              // _goToSelectLocationRoute(state, context);
            },
          ),
        )
    );
  }

  _onParticipantRemoved(PublicUserProfile userProfile) {
    // Do something about this with bloc soon
  }

  _renderParticipantsView() {
    if (widget.participants.isNotEmpty) {
      return MeetupParticipantsList(
        participantUserProfiles: widget.userProfiles,
        onParticipantRemoved: _onParticipantRemoved,
        onParticipantTapped: null,
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

  _renderMeetupNameView() {
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
                // Make changes here
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

  _renderMeetupDateTime() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: _datePickerButton()),
          WidgetUtils.spacer(5),
          Expanded(child: _timePickerButton()),
        ],
      ),
    );
  }

  Widget _timePickerButton() {
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

        // Interact with bloc here
        if(selectedTime != null) {
          setState(() {
            selectedMeetupDate = DateTime(
              selectedMeetupDate.year,
              selectedMeetupDate.month,
              selectedMeetupDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
          });
        }
      },
      child: Text(
          "${selectedMeetupDate.hour}:${selectedMeetupDate.minute}",
          style: const TextStyle(
              fontSize: 16,
              color: Colors.white
          )),
    );
  }

  Widget _datePickerButton() {
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
          firstDate: selectedMeetupDate,
          lastDate: DateTime(ConstantUtils.LATEST_YEAR),
        );

        // Interact
        if(selectedDate != null) {
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

}