import 'dart:async';

import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
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
import 'package:flutter_app/src/views/detailed_meetup/views/meetup_tabs.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/shared_components/participants_list.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
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
  static const int LOCATION_MEETUP_VIEW_TAB = 0;
  static const int AVAILABILITY_MEETUP_VIEW_TAB = 1;
  static const int ACTIVITIES_MEETUP_VIEW_TAB = 2;
  static const int CONVERSATION_MEETUP_VIEW_TAB = 3;

  bool isPremiumEnabled = false;
  int maxOtherChatParticipants = ConstantUtils.MAX_OTHER_CHAT_PARTICIPANTS_FREE;

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

  List<Either<FoodGetResult, FoodGetResultSingleServing>> rawFoodEntries = [];
  Map<String, AllDiaryEntries> participantDiaryEntriesMap = {};
  late List<PublicUserProfile> selectedUserProfilesToShowAvailabilitiesFor;
  late Meetup currentMeetup;

  String initialMeetupOwnerId = "";
  String? initialMeetupName;
  String? initialMeetupLocationId;
  DateTime? initialMeetupDate;
  List<String> initialMeetupParticipantIds = [];

  Map<int, DateTime> timeSegmentToDateTimeMap = {};

  bool isAvailabilitySelectHappening = false;
  bool isParticipantSelectHappening = false;

  bool isKeyboardVisibleCurrently = false;
  int currentSelectedTab = 0;
  late StreamSubscription<bool> keyboardSubscription;

  Timer? debounce;

  _setUpTimeSegmentDateTimeMap(DateTime baseTime) {
    const numberOfIntervals = ((AddOwnerAvailabilitiesViewState.availabilityEndHour - AddOwnerAvailabilitiesViewState.availabilityStartHour) + 1) * 2;
    final intervalsList = List.generate(numberOfIntervals, (i) => i);
    var i = 0;
    var k = 0;
    while (i < intervalsList.length) {
      timeSegmentToDateTimeMap[i] =
          DateTime(baseTime.year, baseTime.month, baseTime.day, k + AddOwnerAvailabilitiesViewState.availabilityStartHour, 0, 0);
      timeSegmentToDateTimeMap[i+1] =
          DateTime(baseTime.year, baseTime.month, baseTime.day, k + AddOwnerAvailabilitiesViewState.availabilityStartHour, 30, 0);

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

    isPremiumEnabled = WidgetUtils.isPremiumEnabledForUser(context);
    if (isPremiumEnabled) {
      maxOtherChatParticipants = ConstantUtils.MAX_OTHER_CHAT_PARTICIPANTS_PREMIUM;
    }

    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {
        isKeyboardVisibleCurrently = visible;
      });
    });
  }

  _fetchAllRequiredDataFromScratch() {
    _detailedMeetupBloc.add(FetchAllMeetupData(
        meetupId: widget.meetupId,
    ));
  }

  _setupWidgetWhenParentSuppliedData() {
    currentMeetup = widget.meetup!;
    selectedMeetupDate = widget.meetup!.time?.toLocal();
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
    initialMeetupOwnerId = currentMeetup.ownerId;
    initialMeetupName = currentMeetup.name;
    initialMeetupLocationId = currentMeetup.locationId;
    initialMeetupDate = currentMeetup.time?.toLocal();
  }


  bool shouldMeetupBeReadOnly() {
    return (currentMeetup.meetupStatus == "Expired" || currentMeetup.meetupStatus == "Complete");
  }

  _onAddParticipantsButtonPressed() {
    if (!shouldMeetupBeReadOnly()) {
      if (isParticipantSelectHappening) {
        // Participant select is already happening, and it has been pressed to toggle
        // We now save participants updated
        _updateMeetingDetails();
      }
    }
    else {
     _showSnackbarForReadOnlyMeetup();
    }
  }

  _showSnackbarForReadOnlyMeetup() {
    if (currentMeetup.meetupStatus == "Expired") {
      SnackbarUtils.showSnackBarShort(context, "Meetup has expired and cannot be edited");
    }
    else {
      SnackbarUtils.showSnackBarShort(context, "Meetup is complete and cannot be edited");
    }
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
              actions: widget.currentUserProfile.userId != currentMeetup?.ownerId ? [
                IconButton(
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.teal,
                  ),
                  onPressed: _goToChatRoom,
                ),
              ] : <Widget>[
                IconButton(
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.teal,
                  ),
                  onPressed: _goToChatRoom,
                ),
                IconButton(
                  icon: Icon(
                    isParticipantSelectHappening ? Icons.check : Icons.add,
                    color: shouldMeetupBeReadOnly() ? Colors.grey : Colors.teal,
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
  void dispose() {
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      appBar: _renderAppBar(),
      floatingActionButton:  _dynamicFloatingActionButtons(),
      body: BlocListener<DetailedMeetupBloc, DetailedMeetupState>(
        listener: (context, state) {
          if (state is DetailedMeetupDataFetched) {
            setState(() {
              _setUpTimeSegmentDateTimeMap(state.meetup.createdAt.toLocal());
              _setLocalStateFromBlocState(state);
              participantDiaryEntriesMap = state.participantDiaryEntriesMap;
              rawFoodEntries = state.rawFoodEntries;
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
          else if (state is MeetupDeletedAndReadyToPop) {
            SnackbarUtils.showSnackBar(context, "Meetup deleted successfully!");
            Navigator.pop(context);
          }
        },
        child: BlocBuilder<DetailedMeetupBloc, DetailedMeetupState>(
          builder: (context, state) {
            if (state is DetailedMeetupDataFetched) {
              return _mainBody(state);
            }
            else if (state is ErrorState) {
              return const Center(
                child: Text("Oops. Looks like this meetup no longer exists!")
              );
            }
            else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  _setLocalStateFromBlocState(DetailedMeetupDataFetched state) {
    selectedMeetupLocation = state.meetupLocation;
    userMeetupAvailabilities = state.userAvailabilities
        .map((key, value) => MapEntry(key, value.map((e) => e.toUpsert()).toList()));

    currentMeetup = state.meetup;
    selectedMeetupDate = state.meetup.time?.toLocal();
    selectedMeetupParticipantUserProfiles = List.from(state.userProfiles);
    selectedMeetupParticipants = List.from(state.participants);
    selectedMeetupParticipantDecisions = List.from(state.decisions);
    selectedMeetupName = state.meetup.name;
    selectedMeetupLocationId = state.meetupLocation?.locationId;
    selectedMeetupLocationFsqId = state.meetupLocation?.location.fsqId;

    selectedUserProfilesToShowAvailabilitiesFor = List.from(state.userProfiles);

    initialMeetupOwnerId = currentMeetup.ownerId;
    initialMeetupLocationId = currentMeetup.locationId;
    initialMeetupDate = currentMeetup.time?.toLocal();
    initialMeetupName = currentMeetup.name;
    initialMeetupParticipantIds = selectedMeetupParticipants.map((e) => e.userId).toList();
  }

  _performMeetupDeletion() {
    ScaffoldMessenger
        .of(context)
        .showSnackBar(const SnackBar(
        content: Text("Please wait... deleting meetup..."),
        duration: SnackbarUtils.shortDuration
    ));
    _detailedMeetupBloc.add(
        DeleteMeetupForUser(
            currentUserId: widget.currentUserProfile.userId,
            meetupId: widget.meetupId
        )
    );
  }

  _showDeleteMeetupButtonIfNeeded() {
    if (widget.currentUserProfile.userId == currentMeetup.ownerId) {
      return Column(
        children: [
          WidgetUtils.spacer(5),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
            ),
            onPressed: () async {
              showDialog(context: context, builder: (context) {
                Widget cancelButton = TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                  ),
                  onPressed:  () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                );
                Widget continueButton = TextButton(
                  onPressed:  () {
                    Navigator.pop(context);
                    _performMeetupDeletion();
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                  ),
                  child: const Text("Confirm"),
                );

                return AlertDialog(
                  title: const Text("Delete Meetup Confirmation"),
                  content: const Text("Are you sure you want to delete this meetup? This action is irreversible!"),
                  actions: [
                    cancelButton,
                    continueButton,
                  ],
                );
              });
            },
            child: const Text("Delete Meetup", style: TextStyle(fontSize: 15, color: Colors.white)),
          ),
        ],
      );
    }
    return null;
  }

  _addSelectedUserIdToParticipantsCallback(PublicUserProfile userProfile) {
    // +1 because currentUser included in selectedMeetupParticipantUserProfiles
    if (selectedMeetupParticipantUserProfiles.length >= maxOtherChatParticipants + 1) {
      if (maxOtherChatParticipants == ConstantUtils.MAX_OTHER_MEETUP_PARTICIPANTS_PREMIUM) {
        SnackbarUtils.showSnackBarShort(context, "Cannot add more than $maxOtherChatParticipants users to a conversation!");
      }
      else {
        WidgetUtils.showUpgradeToPremiumDialog(context, _goToAccountDetailsView);
        SnackbarUtils.showSnackBarShort(context, "Upgrade to premium to add more users to a meetup!");
      }
      selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(userProfile.userId);
    }
    else {
      setState(() {
        selectedMeetupParticipantUserProfiles.add(userProfile);
      });
    }
  }

  _goToAccountDetailsView() {
    Navigator.pushReplacement(
      context,
      HomePage.route(defaultSelectedTab: HomePageState.accountDetails),
    );
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
      SnackbarUtils.showSnackBarShort(context, "You have accepted the meetup invite!");
    }
    else {
      SnackbarUtils.showSnackBarShort(context, "You have declined the meetup invite!");
    }
  }

  _dynamicFloatingActionButtons() {
    // Add accept/decline options if non-owner is viewing it
    return BlocBuilder<DetailedMeetupBloc, DetailedMeetupState>(
      builder: (context, state) {
        if (state is DetailedMeetupDataFetched) {
          if (widget.currentUserProfile.userId != currentMeetup.ownerId) {
            return Visibility(
              visible: !isKeyboardVisibleCurrently,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                      ),
                      onPressed: () async {
                        _addUserDecision(false);
                      },
                      label: const Text("Decline", style: TextStyle(fontSize: 15, color: Colors.white)),
                    )
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                    ),
                    onPressed: () async {
                      _addUserDecision(true);
                    },
                    label: const Text("Accept", style: TextStyle(fontSize: 15, color: Colors.white)),
                  )
                ],
              ),
            );
          }
          else {
            // Hide FAB as saving is now done implicitly on WillPopScope
            // But we still need this because otherwise BlocBuilder will complain
            return Visibility(
              visible: false,
              child: FloatingActionButton(
                  heroTag: "saveButtonDetailedMeetupView",
                  onPressed: () {},
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.save, color: Colors.white)
              ),
            );
          }
        }
        else {
          // We don't use this but we still need this because otherwise BlocBuilder will complain
          return Visibility(
            visible: false,
            child: FloatingActionButton(
                heroTag: "saveButtonDetailedMeetupView",
                onPressed: () {},
                backgroundColor: Colors.teal,
                child: const Icon(Icons.save, color: Colors.white)
            ),
          );
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
  }


  _mainBody(DetailedMeetupDataFetched state) {
    return Column(
      children: WidgetUtils.skipNulls([
        _renderParticipantsView(),
        WidgetUtils.spacer(2.5),
        _showSelectParticipantToViewAvailabilityHintTextIfNeeded(),
        WidgetUtils.spacer(2.5),
        _renderMeetupStatus(),
        WidgetUtils.spacer(2.5),
        Divider(color: Theme.of(context).primaryColor),
        isParticipantSelectHappening ? _participantSelectView(state) : _detailedMeetupView(),
      ]),
    );
  }

  _showSelectParticipantToViewAvailabilityHintTextIfNeeded() {
    if (currentSelectedTab == AVAILABILITY_MEETUP_VIEW_TAB) {
      return const Center(
        child: Text("Tap on a participant to view their availability", style: TextStyle(fontSize: 12),
        ),
      );
    }
    else if (currentSelectedTab == ACTIVITIES_MEETUP_VIEW_TAB) {
      return const Center(
        child: Text("Tap on a participant to view their associated meetup activities", style: TextStyle(fontSize: 12),
        ),
      );
    }
  }

  _renderMeetupStatus() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.5,
            height: 7.5,
            decoration: BoxDecoration(
              color: ColorUtils.meetupStatusToColorMap[currentMeetup.meetupStatus]!,
              shape: BoxShape.circle,
            ),
          ),
          WidgetUtils.spacer(5),
          Text(currentMeetup.meetupStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        ],
      ),
    );
  }

  _getPaddingForTabBarViews(int currentSelectedTab) {
    if (widget.currentUserProfile.userId != currentMeetup.ownerId) {
      switch (currentSelectedTab) {
        case 0: return const EdgeInsets.fromLTRB(0, 0, 0, 20);
        case 1: return const EdgeInsets.fromLTRB(0, 0, 0, 75); //FAB is 56 pixels by default
        case 2: return const EdgeInsets.fromLTRB(0, 0, 0, 75);
      }
    }
    return null;
  }

  _detailedMeetupView() {
    return Expanded(
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: _getPaddingForTabBarViews(currentSelectedTab),
            child: SizedBox(
              height: ScreenUtils.getScreenHeight(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: WidgetUtils.skipNulls([
                  WidgetUtils.spacer(2.5),
                  _renderMeetupNameView(),
                  WidgetUtils.spacer(2.5),
                  _renderMeetupDateTime(),
                  WidgetUtils.spacer(2.5),
                  _renderTabs(),
                  WidgetUtils.spacer(2.5),
                  _showDeleteMeetupButtonIfNeeded(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _renderTabs() {
    return Expanded(
      child: MeetupTabs(
        currentUserProfile: widget.currentUserProfile,
        isAvailabilitySelectHappening: isAvailabilitySelectHappening,
        userMeetupAvailabilities: userMeetupAvailabilities,
        selectedUserProfilesToShowDetailsFor:  selectedUserProfilesToShowAvailabilitiesFor,
        currentMeetup: currentMeetup,
        selectedMeetupParticipantUserProfiles: selectedMeetupParticipantUserProfiles,
        selectedMeetupLocation: selectedMeetupLocation,
        selectedMeetupLocationId: selectedMeetupLocationId,
        selectedMeetupLocationFsqId: selectedMeetupLocationFsqId,
        rawFoodEntries: rawFoodEntries,
        participantDiaryEntriesMap: participantDiaryEntriesMap,
        availabilitiesChangedCallback: _availabilityChangedCallback,
        editAvailabilitiesButtonCallback: _editAvailabilityButtonOnPressed,
        cancelEditAvailabilitiesButtonCallback: _cancelEditAvailabilityButtonOnPressed,
        saveAvailabilitiesButtonCallback: _saveAvailabilityButtonOnPressed,
        searchLocationViewUpdateBlocCallback: _searchLocationViewUpdateBlocCallback,
        currentSelectedTabCallback: _currentSelectedTabCallback,
        searchLocationViewUpdateMeetupLocationViaBlocCallback: _searchLocationViewUpdateMeetupLocationViaBlocCallback
      ),
    );
  }

  _searchLocationViewUpdateMeetupLocationViaBlocCallback() {
    _updateMeetingDetails();
  }

  _cancelEditAvailabilityButtonOnPressed() {
    setState(() {
      isAvailabilitySelectHappening = false;

      final currentState = _detailedMeetupBloc.state;
      if (currentState is DetailedMeetupDataFetched) {
        userMeetupAvailabilities[widget.currentUserProfile.userId] =
            currentState.userAvailabilities[widget.currentUserProfile.userId]!.map((e) => e.toUpsert()).toList();
      }
    });
  }

  _editAvailabilityButtonOnPressed() {
    if (!shouldMeetupBeReadOnly()) {
      setState(() {
        isAvailabilitySelectHappening = true;
      });
    }
    else {
      _showSnackbarForReadOnlyMeetup();
    }
  }

  _saveAvailabilityButtonOnPressed() {
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
    final updatedCurrentUserAvailabilities = MiscUtils.convertBooleanCellStateMatrixToAvailabilities(
        availabilitiesChanged,
        timeSegmentToDateTimeMap
    ).map((e) => MeetupAvailabilityUpsert(
        e.availabilityStart,
        e.availabilityEnd,
    )).toList();

    setState(() {
      userMeetupAvailabilities[widget.currentUserProfile.userId] = updatedCurrentUserAvailabilities;
    });
  }

  _currentSelectedTabCallback(int selectedTab) {
    setState(() {
      currentSelectedTab = selectedTab;
    });
  }

  _searchLocationViewUpdateBlocCallback(Location location) {
    setState(() {
      selectedMeetupLocation = location;
      selectedMeetupLocationId = selectedMeetupLocation?.locationId;
      selectedMeetupLocationFsqId = selectedMeetupLocation?.location.fsqId;
    });
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

  _goToUserProfilePage(PublicUserProfile userProfile) {
    Navigator.pushAndRemoveUntil(
        context,
        UserProfileView.route(userProfile, widget.currentUserProfile),
            (route) => true
    );
  }

  _onParticipantTapped(PublicUserProfile userProfile, bool isSelected) {
    // Select only availabilities to show here
    if (currentSelectedTab != AVAILABILITY_MEETUP_VIEW_TAB && currentSelectedTab != ACTIVITIES_MEETUP_VIEW_TAB) {
      _goToUserProfilePage(userProfile);
    }
    setState(() {
      if (currentSelectedTab != AVAILABILITY_MEETUP_VIEW_TAB) {
        if (isSelected) {
          if (!selectedUserProfilesToShowAvailabilitiesFor.contains(userProfile)) {
            selectedUserProfilesToShowAvailabilitiesFor.add(userProfile);
          }
        }
        else {
          selectedUserProfilesToShowAvailabilitiesFor.remove(userProfile);
        }
      }
      else {
        // This will ensure that only one is ever selected at most
        if (isSelected) {
          selectedUserProfilesToShowAvailabilitiesFor = List.from(List.empty());
          selectedUserProfilesToShowAvailabilitiesFor.add(userProfile);
        }
        else {
          selectedUserProfilesToShowAvailabilitiesFor.remove(userProfile);
        }
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
        shouldTapChangeCircleColour: currentSelectedTab == AVAILABILITY_MEETUP_VIEW_TAB || currentSelectedTab == ACTIVITIES_MEETUP_VIEW_TAB,
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
            readOnly: widget.currentUserProfile.userId != currentMeetup.ownerId || shouldMeetupBeReadOnly(),
            initialValue: selectedMeetupName ?? "Unspecified name",
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onTap: () {
              if (shouldMeetupBeReadOnly()) {
                _showSnackbarForReadOnlyMeetup();
              }
            },
            onChanged: (text) {
              setState(() {
                selectedMeetupName = text;
              });
              if (debounce?.isActive ?? false) debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 500), () {
                _updateMeetingDetails();
              });
            },
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter meetup name',
                hintStyle: const TextStyle(
                    fontWeight: FontWeight.normal
                ),
              filled: widget.currentUserProfile.userId != currentMeetup.ownerId || shouldMeetupBeReadOnly(),
              fillColor: widget.currentUserProfile.userId != currentMeetup.ownerId || shouldMeetupBeReadOnly() ? Colors.grey.shade200 : null
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
        backgroundColor: widget.currentUserProfile.userId == currentMeetup.ownerId && !shouldMeetupBeReadOnly() ?
        MaterialStateProperty.all<Color>(Colors.teal) : MaterialStateProperty.all<Color>(Colors.grey),
      ),
      onPressed: () async {
        if (shouldMeetupBeReadOnly()) {
          _showSnackbarForReadOnlyMeetup();
        }
        else {
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

              _updateMeetingDetails();
            }
          }
          else {
            SnackbarUtils.showSnackBar(context, "Cannot modify meetup time unless you are the owner!");
          }
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
        backgroundColor: widget.currentUserProfile.userId == currentMeetup.ownerId && !shouldMeetupBeReadOnly() ?
            MaterialStateProperty.all<Color>(Colors.teal) : MaterialStateProperty.all<Color>(Colors.grey),
      ),
      onPressed: () async {
        if (shouldMeetupBeReadOnly()) {
          _showSnackbarForReadOnlyMeetup();
        }
        else {
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
              _updateMeetingDetails();
            }
          }
          else {
            SnackbarUtils.showSnackBar(context, "Cannot modify meetup date unless you are the owner!");
          }
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