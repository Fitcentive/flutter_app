import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/datetime_utils.dart';
import 'package:flutter_app/src/utils/misc_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_bloc.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/meetup_comments_list.dart';
import 'package:flutter_app/src/views/shared_components/meetup_location_view.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DetailedMeetupView extends StatefulWidget {
  static const String routeName = "view-meetup";

  final PublicUserProfile currentUserProfile;

  final String meetupId;
  final MeetupLocation? meetupLocation;
  final Meetup? meetup;
  final List<MeetupParticipant>? participants;
  final List<MeetupDecision>? decisions;
  final List<PublicUserProfile>? userProfiles;

  const DetailedMeetupView({
    super.key,
    required this.currentUserProfile,
    required this.meetupId,
    this.meetup,
    this.meetupLocation,
    this.participants,
    this.decisions,
    this.userProfiles
  });

  static Route route({
    required String meetupId,
    required PublicUserProfile currentUserProfile,
    Meetup? meetup,
    MeetupLocation? meetupLocation,
    List<MeetupParticipant>? participants,
    List<MeetupDecision>? decisions,
    List<PublicUserProfile>? userProfiles,
  }
  ) => MaterialPageRoute(
    settings: const RouteSettings(
        name: routeName
    ),
    builder: (_) => DetailedMeetupView.withBloc(
        meetupId: meetupId,
        currentUserProfile: currentUserProfile,
        meetup: meetup,
        meetupLocation: meetupLocation,
        participants: participants,
        decisions: decisions,
        userProfiles: userProfiles,
    )
  );

  static Widget withBloc({
    required String meetupId,
    required PublicUserProfile currentUserProfile,
    Meetup? meetup,
    MeetupLocation? meetupLocation,
    List<MeetupParticipant>? participants,
    List<MeetupDecision>? decisions,
    List<PublicUserProfile>? userProfiles,
  }) => MultiBlocProvider(
    providers: [
      BlocProvider<DetailedMeetupBloc>(
          create: (context) => DetailedMeetupBloc(
            chatRepository: RepositoryProvider.of<ChatRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: DetailedMeetupView(
        meetupId: meetupId,
        meetup: meetup,
        participants: participants,
        decisions: decisions,
        userProfiles: userProfiles,
        meetupLocation: meetupLocation,
        currentUserProfile: currentUserProfile,
    ),
  );

  @override
  State createState() {
    return DetailedMeetupViewState();
  }
}

class DetailedMeetupViewState extends State<DetailedMeetupView> {
  late DetailedMeetupBloc _detailedMeetupBloc;

  DateTime earliestPossibleMeetupDateTime = DateTime.now().add(const Duration(hours: 3));

  List<PublicUserProfile> selectedMeetupParticipantUserProfiles = [];
  List<MeetupParticipant> selectedMeetupParticipants = [];
  List<MeetupDecision> selectedMeetupParticipantDecisions = [];

  DateTime? selectedMeetupDate;
  String? selectedMeetupName;
  Map<String, List<MeetupAvailabilityUpsert>> userMeetupAvailabilities = {};

  Location? selectedMeetupLocation;
  String? selectedMeetupLocationId;
  String? selectedMeetupLocationFsqId;

  late List<PublicUserProfile> selectedUserProfilesToShowAvailabilitiesFor;
  late Meetup currentMeetup;

  Map<int, DateTime> timeSegmentToDateTimeMap = {};

  bool isAvailabilitySelectHappening = false;
  bool isParticipantSelectHappening = false;

  _setUpTimeSegmentDateTimeMap(DateTime baseTime) {
    const numberOfIntervals = (AddOwnerAvailabilitiesViewState.availabilityEndHour - AddOwnerAvailabilitiesViewState.availabilityStartHour) * 2;
    final intervalsList = List.generate(numberOfIntervals, (i) => i);
    var i = 0;
    var k = 0;
    while (i < intervalsList.length) {
      timeSegmentToDateTimeMap[i] =
          DateTime.utc(baseTime.year, baseTime.month, baseTime.day, k + AddOwnerAvailabilitiesViewState.availabilityStartHour, 0, 0);
      timeSegmentToDateTimeMap[i+1] =
          DateTime.utc(baseTime.year, baseTime.month, baseTime.day, k + AddOwnerAvailabilitiesViewState.availabilityStartHour, 30, 0);

      i += 2;
      k += 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _detailedMeetupBloc = BlocProvider.of<DetailedMeetupBloc>(context);

    if (widget.meetup != null && widget.userProfiles != null && widget.participants != null && widget.decisions != null) {
      _setupWidgetWhenParentSuppliedData();
    }
    else {
      _fetchAllRequiredDataFromScratch();
    }

  }

  _fetchAllRequiredDataFromScratch() {
    _detailedMeetupBloc.add(FetchAllMeetupData(
        meetupId: widget.meetupId,
    ));
  }

  _setupWidgetWhenParentSuppliedData() {
    currentMeetup = widget.meetup!;
    selectedMeetupDate = widget.meetup!.time;
    selectedMeetupParticipantUserProfiles = List.from(widget.userProfiles!);
    selectedMeetupParticipants = List.from(widget.participants!);
    selectedMeetupParticipantDecisions = List.from(widget.decisions!);
    selectedMeetupName = widget.meetup!.name;
    selectedMeetupLocationId = widget.meetupLocation?.id;
    selectedMeetupLocationFsqId = widget.meetupLocation?.fsqId;

    _detailedMeetupBloc.add(FetchAdditionalMeetupData(
      meetupId: widget.meetup!.id,
      participantIds: widget.participants!.map((e) => e.userId).toList(),
      meetupLocationFsqId: widget.meetupLocation?.fsqId,
      meetup: widget.meetup!,
      participants: widget.participants!,
      decisions: widget.decisions!,
      userProfiles: widget.userProfiles!,
    ));

    selectedUserProfilesToShowAvailabilitiesFor = List.from(widget.userProfiles!);
  }


  _onAddParticipantsButtonPressed() {
    setState(() {
      isParticipantSelectHappening = !isParticipantSelectHappening;
    });
  }

  _renderAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: BlocBuilder<DetailedMeetupBloc, DetailedMeetupState>(
        builder: (context, state) {
          if (state is DetailedMeetupDataFetched) {
            return AppBar(
              title: const Text("View Meetup", style: TextStyle(color: Colors.teal)),
              iconTheme: const IconThemeData(color: Colors.teal),
              actions: widget.currentUserProfile.userId != currentMeetup?.ownerId ? [] : <Widget>[
                IconButton(
                  icon: Icon(
                    isParticipantSelectHappening ? Icons.check : Icons.add,
                    color: Colors.teal,
                  ),
                  onPressed: _onAddParticipantsButtonPressed,
                )
              ],
            );
          }
          else {
            return AppBar(
              title: const Text("View Meetup", style: TextStyle(color: Colors.teal)),
              iconTheme: const IconThemeData(color: Colors.teal),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _renderAppBar(),
      floatingActionButton:  _dynamicFloatingActionButtons(),
      body: WillPopScope(
        onWillPop: () {
          _updateMeetingDetails();
          return Future.value(false);
        },
        child: BlocListener<DetailedMeetupBloc, DetailedMeetupState>(
          listener: (context, state) {
            if (state is DetailedMeetupDataFetched) {
              setState(() {
                _setUpTimeSegmentDateTimeMap(state.meetup.createdAt);

                selectedMeetupLocation = state.meetupLocation;
                userMeetupAvailabilities = state.userAvailabilities
                    .map((key, value) => MapEntry(key, value.map((e) => e.toUpsert()).toList()));

                currentMeetup = state.meetup;
                selectedMeetupDate = state.meetup.time;
                selectedMeetupParticipantUserProfiles = List.from(state.userProfiles);
                selectedMeetupParticipants = List.from(state.participants);
                selectedMeetupParticipantDecisions = List.from(state.decisions);
                selectedMeetupName = state.meetup.name;
                selectedMeetupLocationId = state.meetupLocation?.locationId;
                selectedMeetupLocationFsqId = state.meetupLocation?.location.fsqId;

                selectedUserProfilesToShowAvailabilitiesFor = List.from(state.userProfiles);
              });
            }
            else if (state is MeetupChatRoomCreated) {
              final otherUserProfiles = selectedMeetupParticipantUserProfiles
                  .where((element) => element.userId != widget.currentUserProfile.userId)
                  .toList();

              Navigator.push(
                  context,
                  UserChatView.route(
                      currentRoomId: state.chatRoomId,
                      currentUserProfile: widget.currentUserProfile,
                      otherUserProfiles: otherUserProfiles
                  )
              );
            }
            else if (state is MeetupUpdatedAndReadyToPop) {
              SnackbarUtils.showSnackBar(context, "Meetup updated successfully!");
              Navigator.pop(context);
            }
          },
          child: BlocBuilder<DetailedMeetupBloc, DetailedMeetupState>(
            builder: (context, state) {
              if (state is DetailedMeetupDataFetched) {
                return _mainBody(state);
              }
              else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  _addSelectedUserIdToParticipantsCallback(PublicUserProfile userProfile) {
    setState(() {
      selectedMeetupParticipantUserProfiles.add(userProfile);
    });
  }


  _removeSelectedUserIdToParticipantsCallback(PublicUserProfile userProfile) {
    setState(() {
      selectedMeetupParticipantUserProfiles.remove(userProfile);
    });
  }

  _participantSelectView(DetailedMeetupDataFetched state) {
    return SelectFromUsersView.withBloc(
        key: selectFromFriendsViewStateGlobalKey,
        currentUserId: widget.currentUserProfile.userId,
        currentUserProfile: widget.currentUserProfile,
        addSelectedUserIdToParticipantsCallback: _addSelectedUserIdToParticipantsCallback,
        removeSelectedUserFromToParticipantsCallback: _removeSelectedUserIdToParticipantsCallback,
        alreadySelectedUserProfiles: selectedMeetupParticipantUserProfiles,
        isRestrictedOnlyToFriends: true,
    );
  }

  _addUserDecision(bool hasUserAcceptedMeetup) {
    _detailedMeetupBloc.add(
        AddParticipantDecisionToMeetup(
            meetupId: currentMeetup.id,
            participantId: widget.currentUserProfile.userId,
            hasAccepted: hasUserAcceptedMeetup
        )
    );
    if (hasUserAcceptedMeetup) {
      SnackbarUtils.showSnackBar(context, "You have successfully accepted the meetup invite!");
    }
    else {
      SnackbarUtils.showSnackBar(context, "You have successfully declined the meetup invite!");
    }
    Navigator.pop(context);
  }

  _dynamicFloatingActionButtons() {
    // Add accept/decline options if non-owner is viewing it
    return BlocBuilder<DetailedMeetupBloc, DetailedMeetupState>(
      builder: (context, state) {
        if (state is DetailedMeetupDataFetched) {
          if (widget.currentUserProfile.userId != currentMeetup.ownerId) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                  child: FloatingActionButton(
                      heroTag: "declineButtonDetailedMeetupView",
                      onPressed: () {
                        _addUserDecision(false);
                      },
                      backgroundColor: Colors.redAccent,
                      tooltip: "Decline",
                      child: const Icon(Icons.close, color: Colors.white)
                  ),
                ),
                FloatingActionButton(
                    heroTag: "acceptButtonDetailedMeetupView",
                    onPressed: () {
                      _addUserDecision(true);
                    },
                    backgroundColor: Colors.teal,
                    tooltip: "Accept",
                    child: const Icon(Icons.check, color: Colors.white)
                )
              ],
            );
          }
          else {
            // Hide FAB as saving is now done implicitly on WillPopScope
            return Visibility(
              visible: false,
              child: FloatingActionButton(
                  heroTag: "saveButtonDetailedMeetupView",
                  onPressed: _updateMeetingDetails,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.save, color: Colors.white)
              ),
            );
          }
        }
        else {
          return Visibility(
            visible: false,
            child: FloatingActionButton(
                heroTag: "saveButtonDetailedMeetupView",
                onPressed: () {},
                backgroundColor: Colors.teal,
                child: const Icon(Icons.save, color: Colors.white)
            ),
          );;
        }
      },
    );

  }

  void _updateMeetingDetails() {
    _detailedMeetupBloc.add(UpdateMeetupDetails(
        meetupId: currentMeetup.id,
        meetupTime: selectedMeetupDate,
        meetupName: selectedMeetupName,
        location: selectedMeetupLocation,
        meetupParticipantUserIds: selectedMeetupParticipantUserProfiles.map((e) => e.userId).toList(),
    ));
    ScaffoldMessenger
        .of(context)
        .showSnackBar(const SnackBar(
          content: Text("Please wait... updating meetup..."),
          duration: SnackbarUtils.shortDuration
    ));
  }


  _mainBody(DetailedMeetupDataFetched state) {
    return Column(
      children: [
        _renderParticipantsView(),
        WidgetUtils.spacer(2.5),
        const Center(child: Text("Tap on a participant to view their availability"),),
        Divider(color: Theme.of(context).primaryColor),
        isParticipantSelectHappening ? _participantSelectView(state) : Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 75), //FAB is 56 pixels by default
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetUtils.skipNulls([
                    WidgetUtils.spacer(2.5),
                    _renderMeetupNameView(),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupChatButton(),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupDateTime(),
                    WidgetUtils.spacer(2.5),
                    _renderEditAvailabilitiesButton(),
                    WidgetUtils.spacer(2.5),
                    _renderAvailabilitiesView(),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupLocation(),
                    WidgetUtils.spacer(2.5),
                    _renderMeetupFsqLocationCardIfNeeded(),
                    WidgetUtils.spacer(5),
                    _renderMeetupCommentsHeader(),
                    WidgetUtils.spacer(5),
                    _renderMeetupComments(),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _renderMeetupCommentsHeader() {
    return const Text(
      "Activity",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20
      ),
    );
  }

  _renderMeetupComments() {
    return LimitedBox(
        maxHeight: 400,
        child: MeetupCommentsListView.withBloc(
            currentUserId: widget.currentUserProfile.userId,
            meetupId: currentMeetup.id
        )
    );
  }

  _renderEditAvailabilitiesButton() {
    if (isAvailabilitySelectHappening) {
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 5),
       child: Row(
         mainAxisSize: MainAxisSize.max,
         children: [
           Expanded(
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
               onPressed: () {
                 setState(() {
                   isAvailabilitySelectHappening = false;

                   final currentState = _detailedMeetupBloc.state;
                   if (currentState is DetailedMeetupDataFetched) {
                     userMeetupAvailabilities[widget.currentUserProfile.userId] =
                         currentState.userAvailabilities[widget.currentUserProfile.userId]!.map((e) => e.toUpsert()).toList();
                   }
                 });
               },
               child: const Text("Cancel edits"),
             ),
           ),
           WidgetUtils.spacer(5),
           Expanded(
             child: ElevatedButton(
               onPressed: () {
                 setState(() {
                   isAvailabilitySelectHappening = false;
                 });

                 _detailedMeetupBloc.add(
                     SaveAvailabilitiesForCurrentUser(
                       meetupId: currentMeetup.id,
                       currentUserId: widget.currentUserProfile.userId,
                       availabilities: userMeetupAvailabilities[widget.currentUserProfile.userId]!,
                     )
                 );
               },
               child: const Text("Save edits"),
             ),
           ),
         ],
       ),
     );
    }
    else {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              isAvailabilitySelectHappening = true;
            });
          },
          child: const Text("Edit your availability"),
        ),
      );
    }
  }

  _renderAvailabilityHeaders(DateTime initialDay) {
    return List.generate(AddOwnerAvailabilitiesViewState.availabilityDaysAhead, (i) {
      final currentDate = initialDay.add(Duration(days: i));
      return TimePlannerTitle(
        date: DateFormat("MMM-dd").format(currentDate),
        title: DateFormat("EEEE").format(currentDate),
      );
    });
  }

  // This is only triggered if the supplied currentUserAcceptingAvailabilityFor is not null
  _availabilityChangedCallback(List<List<bool>> availabilitiesChanged) {
    // For some reason, this callback only is going ahead by 5.5 hours. Fix dirty hack
    final updatedCurrentUserAvailabilities = MiscUtils.convertBooleanMatrixToAvailabilities(
        availabilitiesChanged,
        timeSegmentToDateTimeMap
    ).map((e) => MeetupAvailabilityUpsert(
        e.availabilityStart.subtract(const Duration(hours: 5, minutes: 30)),
        e.availabilityEnd.subtract(const Duration(hours: 5, minutes: 30)),
    )).toList();

    setState(() {
      userMeetupAvailabilities[widget.currentUserProfile.userId] = updatedCurrentUserAvailabilities;
    });
  }

  _renderAvailabilitiesView() {
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DiscreteAvailabilitiesView(
          currentUserAcceptingAvailabilityFor: isAvailabilitySelectHappening ? widget.currentUserProfile.userId : null,
          availabilityChangedCallback: _availabilityChangedCallback,
          startHour: AddOwnerAvailabilitiesViewState.availabilityStartHour,
          endHour: AddOwnerAvailabilitiesViewState.availabilityEndHour,
          style: TimePlannerStyle(
            // cellHeight: 60,
            // cellWidth: 60,
            showScrollBar: true,
          ),
          headers: _renderAvailabilityHeaders(currentMeetup.createdAt),
          tasks: const [],
          availabilityInitialDay: currentMeetup.createdAt,
          meetupAvailabilities: Map.fromEntries(userMeetupAvailabilities
              .entries
              .where((element) =>
                  selectedUserProfilesToShowAvailabilitiesFor.map((e) => e.userId).contains(element.key))),
        ),
      ),
    );
  }

  // Need an API call to fetch the FSQ result, wait for bloc to complete
  _renderMeetupFsqLocationCardIfNeeded() {
    if (selectedMeetupLocation == null) {
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
      return SizedBox(
        height: 275,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: FoursquareLocationCardView(
              locationId: selectedMeetupLocation!.locationId,
              location: selectedMeetupLocation!.location,
            ),
          ),
        ),
      );
    }
  }

  _renderMeetupLocation() {
    return SizedBox(
        height: ScreenUtils.getScreenHeight(context) * 0.25,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MeetupLocationView(
            currentUserProfile: widget.currentUserProfile,
            meetupLocation: selectedMeetupLocation?.toMeetupLocation(),
            userProfiles: selectedMeetupParticipantUserProfiles,
            onTapCallback: () {
              // Go to select location route
              if (widget.currentUserProfile.userId == currentMeetup.ownerId) {
                _goToSelectLocationRoute();
              }
            },
          ),
        )
    );
  }

  _goToSelectLocationRoute() {
    Navigator.pushAndRemoveUntil(
        context,
        SearchLocationsView.route(
            userProfilesWithLocations: selectedMeetupParticipantUserProfiles
                .map((e) => UserProfileWithLocation(e, e.locationCenter!.latitude, e.locationCenter!.longitude, e.locationRadius!.toDouble()))
                .toList(),
            initialSelectedLocationId: selectedMeetupLocationId,
            initialSelectedLocationFsqId: selectedMeetupLocationFsqId,
            updateBlocCallback: (location) {
              setState(() {
                selectedMeetupLocation = location;
                selectedMeetupLocationId = selectedMeetupLocation?.locationId;
                selectedMeetupLocationFsqId = selectedMeetupLocation?.location.fsqId;
              });
            }),
            (route) => true
    );
  }

  _onParticipantRemoved(PublicUserProfile userProfile) {
    // We ensure that the owner is now removed
    if (widget.currentUserProfile.userId == currentMeetup.ownerId) {
      if (userProfile.userId != currentMeetup.ownerId) {
        setState(() {
          selectedMeetupParticipantUserProfiles.remove(userProfile);
        });
        selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(userProfile.userId);
      }
      else {
        SnackbarUtils.showSnackBar(context, "Cannot remove owner from participants list!");
      }
    }
    else {
      SnackbarUtils.showSnackBar(context, "Cannot modify meetup participants unless you are the owner!");
    }
  }

  _onParticipantTapped(PublicUserProfile userProfile, bool isSelected) {
    // Select only availabilities to show here
    setState(() {
      if (isSelected) {
        if (!selectedUserProfilesToShowAvailabilitiesFor.contains(userProfile)) {
          selectedUserProfilesToShowAvailabilitiesFor.add(userProfile);
        }
      }
      else {
        selectedUserProfilesToShowAvailabilitiesFor.remove(userProfile);
      }
    });
  }

  _renderParticipantsView() {
    if (selectedMeetupParticipants.isNotEmpty) {
      return ParticipantsList(
        participantUserProfiles: selectedMeetupParticipantUserProfiles,
        onParticipantRemoved: _onParticipantRemoved,
        onParticipantTapped: _onParticipantTapped,
        participantDecisions: selectedMeetupParticipantDecisions,
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

  _goToChatRoom() {
    if (selectedMeetupParticipants.length < 3) {
      _detailedMeetupBloc.add(
          // Get chat room and listen for this and jump to it
          GetDirectMessagePrivateChatRoomForMeetup(
              meetup: currentMeetup,
              currentUserProfileId: widget.currentUserProfile.userId,
              participants: widget.participants!.map((e) => e.userId).toList(),
          )
      );
    }
    else if (currentMeetup.chatRoomId != null) {
      final otherUserProfiles = selectedMeetupParticipantUserProfiles
          .where((element) => element.userId != widget.currentUserProfile.userId)
          .toList();

      Navigator.push(
        context,
        UserChatView.route(
            currentRoomId: currentMeetup.chatRoomId!,
            currentUserProfile: widget.currentUserProfile,
            otherUserProfiles: otherUserProfiles
        )
      );
    }
    else {
      // Create chat room first as it doenst exist, and then listen for it and jump
      _detailedMeetupBloc.add(
          CreateChatRoomForMeetup(
              meetup: currentMeetup,
              roomName: currentMeetup.name ?? "Unnamed meetup",
              participants: widget.participants!.map((e) => e.userId).toList()
          )
      );
    }
  }

  _renderMeetupChatButton() {
    return Center(
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

  _renderMeetupNameView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextFormField(
            readOnly: widget.currentUserProfile.userId != currentMeetup.ownerId,
            initialValue: selectedMeetupName ?? "Unspecified name",
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onChanged: (text) {
              setState(() {
                selectedMeetupName = text;
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
        if (widget.currentUserProfile.userId == currentMeetup.ownerId) {
          final selectedTime = await showTimePicker(
            initialTime: TimeOfDay.fromDateTime(selectedMeetupDate ?? earliestPossibleMeetupDateTime),
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
                (selectedMeetupDate ?? earliestPossibleMeetupDateTime).year,
                (selectedMeetupDate ?? earliestPossibleMeetupDateTime).month,
                (selectedMeetupDate ?? earliestPossibleMeetupDateTime).day,
                selectedTime.hour,
                selectedTime.minute,
              );
            });
          }
        }
        else {
          SnackbarUtils.showSnackBar(context, "Cannot modify meetup time unless you are the owner!");
        }
      },
      child: Text(
          selectedMeetupDate == null ? "Time unset" : DateFormat("hh:mm a").format(selectedMeetupDate!),
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
        if (widget.currentUserProfile.userId == currentMeetup.ownerId) {
          final selectedDate = await showDatePicker(
            builder: (BuildContext context, Widget? child) {
              return Theme(
                  data: ThemeData(primarySwatch: Colors.teal),
                  child: child!
              );
            },
            context: context,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDate: selectedMeetupDate ?? earliestPossibleMeetupDateTime,
            firstDate: DateTimeUtils.calcMinDate(WidgetUtils.skipNulls([selectedMeetupDate, earliestPossibleMeetupDateTime])),
            lastDate: DateTime(ConstantUtils.LATEST_YEAR),
          );

          // Interact
          if(selectedDate != null) {
            setState(() {
              selectedMeetupDate = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                (selectedMeetupDate ?? earliestPossibleMeetupDateTime).hour,
                (selectedMeetupDate ?? earliestPossibleMeetupDateTime).minute,
              );
            });
          }
        }
        else {
          SnackbarUtils.showSnackBar(context, "Cannot modify meetup date unless you are the owner!");
        }
      },
      child: Text(
          selectedMeetupDate == null ? "Date unset" : DateFormat('yyyy-MM-dd').format(selectedMeetupDate!),
          style: const TextStyle(
              fontSize: 16,
              color: Colors.white
          )),
    );
  }

}