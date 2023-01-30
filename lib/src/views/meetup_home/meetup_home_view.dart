import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/create_new_meetup_view.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_bloc.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_event.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_state.dart';
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

  @override
  void initState() {
    super.initState();

    _meetupHomeBloc = BlocProvider.of<MeetupHomeBloc>(context);
    _meetupHomeBloc.add(FetchUserMeetupData(widget.currentUserProfile.userId));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        isDataBeingRequested = true;
        _meetupHomeBloc.add(FetchMoreUserMeetupData(widget.currentUserProfile.userId));
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
            if (state is MeetupUserDataFetched) {
              isDataBeingRequested = false;
              if (state.meetups.isEmpty) {
                return const Center(
                  child: Text("No meetups here... get started by creating one!"),
                );
              }
              else {
                return _renderMeetupsListView(state);
              }
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

  _renderMeetupsListView(MeetupUserDataFetched state) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: state.doesNextPageExist ? state.meetups.length + 1 : state.meetups.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= state.meetups.length) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final currentMeetupItem = state.meetups[index];
            return _meetupCardItem(
                currentMeetupItem,
                state.meetupParticipants[currentMeetupItem.id]!,
                state.meetupDecisions[currentMeetupItem.id]!,
                state.userIdProfileMap
            );
          }
        },
      ),
    );
  }

  _meetupCardItem(
      Meetup meetup,
      List<MeetupParticipant> participants,
      List<MeetupDecision> decisions,
      Map<String, PublicUserProfile> userIdProfileMap
  ) {
    final relevantUserProfiles =
      userIdProfileMap.values.where((element) => participants.map((e) => e.userId).contains(element.userId)).toList();
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Card(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: WidgetUtils.skipNulls(
                    [
                      _renderTop(meetup),
                      WidgetUtils.spacer(5),
                      _renderBottom(meetup, participants, decisions, relevantUserProfiles),
                    ]
                ),
              ),
            ),
          ),
        )
    );
  }

  _renderBottom(
    Meetup meetup,
    List<MeetupParticipant> participants,
    List<MeetupDecision> decisions,
    List<PublicUserProfile> userProfiles
  ) {
    return Row(
      children: [
        // This part is supposed to be locations view
        Flexible(
          flex: 3,
          child: _renderMapBox(userProfiles),
        ),
        // This part is supposed to be participant list
        Flexible(
            flex: 2,
            child: _renderParticipantsList(participants, userProfiles, decisions)
        )
      ],
    );
  }

  _renderParticipantsList(
      List<MeetupParticipant> participants,
      List<PublicUserProfile> userProfiles,
      List<MeetupDecision> decisions) {
    return const Text("Yet to come....");
  }


  _renderMapBox(List<PublicUserProfile> userProfiles) {
    _setupMap(userProfiles, context);
    return GoogleMap(
        onTap: (_) {
          // _goToLocationView(userProfile, context);
        },
        mapType: MapType.hybrid,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
        markers: markers,
        circles: Set<Circle>.of(circles.values),
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        }
    );
  }

  void _generateBoundaryCircleForUserProfile(PublicUserProfile profile, BuildContext context) {
    final newCircleId = CircleId(profile.userId);
    final Circle circle = Circle(
      circleId: newCircleId,
      strokeColor: Colors.tealAccent,
      consumeTapEvents: true,
      onTap: () {
        // _goToLocationView(userProfile, context);
      },
      fillColor: Colors.teal.withOpacity(0.5),
      strokeWidth: 5,
      center: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      radius: profile.locationRadius!.toDouble(),
    );
    circles[newCircleId] = circle;
  }

  _setupMap(List<PublicUserProfile> users, BuildContext context) {
    markers.clear();
    circles.clear();
    users.forEach((user) {
      _generateBoundaryCircleForUserProfile(user, context);
      markers.add(
        Marker(
          markerId: MarkerId(user.userId),
          position: LatLng(user.locationCenter!.latitude, user.locationCenter!.longitude),
        ),
      );
    });

    _initialCameraPosition = CameraPosition(
        target: LocationUtils.computeCentroid(markers.toList().map((e) => e.position)),
        tilt: 0,
        zoom: LocationUtils.getZoomLevelMini(users.map((e) => e.locationRadius!).reduce(max).toDouble())
    );

    _snapCameraToMarkers();

  }

  _snapCameraToMarkers() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(LocationUtils.generateBoundsFromMarkers(markers), 50));
  }

  _renderTop(Meetup meetup) {
    return Row(
      children: [
        // Name, date and time
        Flexible(
          flex: 3,
          child: Column(
            children: [
              Text(meetup.name ?? "Unnamed meetup", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, ),),
              Text("${meetup.time?.hour}:${meetup.time?.minute}", style: const TextStyle(fontSize: 12),),
              Text("${meetup.time?.year}-${meetup.time?.month}-${meetup.time?.day}", style: const TextStyle(fontSize: 12),),
            ],
          ),
        ),
        Flexible(
          flex: 2,
          child: Center(
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(meetup.meetupStatus, style: const TextStyle(fontSize: 12),),
              ],
            ),
          )
        )
      ],
    );
  }

  _animatedButton() {
    return AnimatedOpacity(
      opacity: _isFloatingButtonVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: _isFloatingButtonVisible,
        child: FloatingActionButton(
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
    Navigator.pushAndRemoveUntil(context, CreateNewMeetupView.route(widget.currentUserProfile), (route) => true);
  }
}