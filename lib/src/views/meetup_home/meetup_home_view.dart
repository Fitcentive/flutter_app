import 'dart:async';

import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/create_new_meetup_view.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_bloc.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_event.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/meetup_card_view.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MeetupHomeView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const MeetupHomeView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<MeetupHomeBloc>(
          create: (context) => MeetupHomeBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: MeetupHomeView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return MeetupHomeViewState();
  }
}

class MeetupHomeViewState extends State<MeetupHomeView> {
  static const double _scrollThreshold = 200.0;

  bool isDataBeingRequested = false;
  bool _isFloatingButtonVisible = true;

  final _scrollController = ScrollController();
  late final MeetupHomeBloc _meetupHomeBloc;

  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();
  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  CircleId circleId = const CircleId('radius_circle');
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  Map<String, BitmapDescriptor?> userIdToMapMarkerIcon = {};
  Map<String, Color> userIdToMapMarkerColor = {};
  List<Color> usedColoursThusFar = [];

  late Future<int> setupIconResult;
  late BitmapDescriptor customGymLocationIcon;

  String? selectedFilterByOption;
  String? selectedStatusOption;

  @override
  void initState() {
    super.initState();

    _meetupHomeBloc = BlocProvider.of<MeetupHomeBloc>(context);
    _meetupHomeBloc.add(
        FetchUserMeetupData(
          userId: widget.currentUserProfile.userId,
        )
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        isDataBeingRequested = true;
        _meetupHomeBloc.add(
            FetchMoreUserMeetupData(
                userId: widget.currentUserProfile.userId,
                selectedStatusOption: selectedStatusOption,
                selectedFilterByOption: selectedFilterByOption
            )
        );
      }

      // Handle floating action button visibility
      if(_scrollController.position.userScrollDirection == ScrollDirection.reverse){
        if(_isFloatingButtonVisible == true) {
          setState((){
            _isFloatingButtonVisible = false;
          });
        }
      } else {
        if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
          if (_isFloatingButtonVisible == false) {
            setState(() {
              _isFloatingButtonVisible = true;
            });
          }
        }
      }

    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _animatedButton(),
      body: BlocListener<MeetupHomeBloc, MeetupHomeState>(
        listener: (context, state) {

        },
        child: BlocBuilder<MeetupHomeBloc, MeetupHomeState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _renderMeetupUserFilters(),
                  WidgetUtils.spacer(2.5),
                  _renderMeetupStatusFilters(),
                  WidgetUtils.spacer(2.5),
                  _renderBody(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _renderBody(MeetupHomeState state) {
    if (state is MeetupUserDataFetched) {
      isDataBeingRequested = false;
      if (state.meetups.isEmpty) {
        return LimitedBox(
          maxHeight: ScreenUtils.getScreenHeight(context) * 0.7,
          child: const Center(
            child: Text("No meetups here... get started by creating one!"),
          ),
        );
      }
      else {
        return _renderMeetupsListView(state);
      }
    }
    else {
      return LimitedBox(
        maxHeight: ScreenUtils.getScreenHeight(context) * 0.7,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  _filterItem(String filterType, String text) {
    final Color backgroundColor;
    final Color textColor;
    if (filterType == "status") {
      if (selectedStatusOption == text) {
        backgroundColor = Colors.teal;
        textColor = Colors.white;
      }
      else {
        backgroundColor = Colors.white;
        textColor = Colors.teal;
      }
    }
    else {
      if (selectedFilterByOption == text) {
        backgroundColor = Colors.teal;
        textColor = Colors.white;
      }
      else {
        backgroundColor = Colors.white;
        textColor = Colors.teal;
      }
    }

    return GestureDetector(
      onTap: () {
        if (filterType == "status") {
          setState(() {
            if (selectedStatusOption == text) {
              selectedStatusOption = null;
            }
            else {
              selectedStatusOption = text;
            }
          });
        }
        else {
          setState(() {
            if (selectedFilterByOption == text) {
              selectedFilterByOption = null;
            }
            else {
              selectedFilterByOption = text;
            }
          });
        }
        _meetupHomeBloc.add(
            FetchUserMeetupData(
              userId: widget.currentUserProfile.userId,
              selectedFilterByOption: selectedFilterByOption,
              selectedStatusOption: selectedStatusOption,
            )
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: backgroundColor,
          boxShadow: const [
            BoxShadow(color: Colors.teal, spreadRadius: 1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
              text,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
              )
          ),
        ),
      ),
    );
  }

  _renderMeetupUserFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              "Filter by",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14
              ),
            )
          ),
          Expanded(
              flex: 8,
              child: Wrap(
                  runSpacing: 5,
                  spacing: 2.5,
                  direction: Axis.horizontal,
                  children: <Widget>[
                    _filterItem("filterBy", "Created"),
                    _filterItem("filterBy", "Joined"),
                    _filterItem("filterBy", "Active"),
                    _filterItem("filterBy", "Complete"),
                    // Gap()
                  ]
              )
          )
        ],
      ),
    );
  }

  _renderMeetupStatusFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Expanded(
              flex: 2,
              child: Text(
                "Status",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14
                ),
              )
          ),
          Expanded(
              flex: 8,
              child: Wrap(
                  direction: Axis.horizontal,
                  runSpacing: 5,
                  spacing: 2.5,
                  children: <Widget>[
                    _filterItem("status", "Unscheduled"),
                    _filterItem("status", "Confirmed"),
                    _filterItem("status", "Unconfirmed"),
                    _filterItem("status", "Complete"),
                    _filterItem("status", "Expired"),
                    // Gap()
                  ]
              )
          )
        ],
      ),
    );
  }

  _pullToRefresh() {
    _meetupHomeBloc.add(
        FetchUserMeetupData(
          userId: widget.currentUserProfile.userId,
          selectedFilterByOption: selectedFilterByOption,
          selectedStatusOption: selectedStatusOption,
        )
    );
  }

  _renderMeetupsListView(MeetupUserDataFetched state) {
    return RefreshIndicator(
      onRefresh: () async {
        _pullToRefresh();
      },
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          controller: _scrollController,
          itemCount: state.doesNextPageExist ? state.meetups.length + 1 : state.meetups.length,
          itemBuilder: (BuildContext context, int index) {
            if (index >= state.meetups.length) {
              return const Center(child: CircularProgressIndicator());
            } else {
              final currentMeetupItem = state.meetups[index];
              final currentMeetupLocation = state.meetupLocations[index];
              final currentMeetupParticipants = state.meetupParticipants[currentMeetupItem.id]!;
              final currentMeetupDecisions = state.meetupDecisions[currentMeetupItem.id]!;
              return MeetupCardView.withBloc(
                  currentUserProfile: widget.currentUserProfile,
                  meetup: currentMeetupItem,
                  meetupLocation: currentMeetupLocation,
                  participants: currentMeetupParticipants,
                  decisions: currentMeetupDecisions,
                  userIdProfileMap: state.userIdProfileMap,
                  onCardTapped: () {
                    _goToEditMeetupView(
                        currentMeetupItem,
                        currentMeetupLocation,
                        currentMeetupParticipants,
                        currentMeetupDecisions,
                        state.userIdProfileMap.values.where((element) => currentMeetupParticipants.map((e) => e.userId).contains(element.userId)).toList()
                    );
                  },
                onChatButtonPressed: (chatRoomId, otherUserProfiles) {
                  Navigator.push(
                      context,
                      UserChatView.route(
                        currentRoomId: chatRoomId,
                        currentUserProfile: widget.currentUserProfile,
                        otherUserProfiles: otherUserProfiles,
                      )
                  );
                }
              );
            }
          },
        ),
      ),
    );
  }

  _goToEditMeetupView(
      Meetup meetup,
      MeetupLocation? meetupLocation,
      List<MeetupParticipant> participants,
      List<MeetupDecision> decisions,
      List<PublicUserProfile> relevantUserProfiles,
      ) {
    Navigator.push(
      context,
      DetailedMeetupView.route(
          meetupId: meetup.id,
          meetup: meetup,
          meetupLocation: meetupLocation,
          participants: participants,
          decisions: decisions,
          userProfiles: relevantUserProfiles,
          currentUserProfile: widget.currentUserProfile
      ),
    ).then((value) {
      _meetupHomeBloc.add(
          FetchUserMeetupData(
            userId: widget.currentUserProfile.userId,
            selectedFilterByOption: selectedFilterByOption,
            selectedStatusOption: selectedStatusOption,
          )
      );
    });
  }


  _animatedButton() {
    return AnimatedOpacity(
      opacity: _isFloatingButtonVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: _isFloatingButtonVisible,
        child: FloatingActionButton(
          heroTag: "MeetupHomeViewCreateNewMeetupButton",
          onPressed: () {
            _goToCreateNewMeetupView();
          },
          tooltip: 'Create new meetup!',
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  _goToCreateNewMeetupView() {
    Navigator
        .pushAndRemoveUntil(context, CreateNewMeetupView.route(widget.currentUserProfile), (route) => true)
    .then((value) {
      _meetupHomeBloc.add(
          FetchUserMeetupData(
            userId: widget.currentUserProfile.userId,
            selectedFilterByOption: selectedFilterByOption,
            selectedStatusOption: selectedStatusOption,
          )
      );
    });
  }
}