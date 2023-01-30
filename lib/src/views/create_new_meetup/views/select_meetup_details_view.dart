import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/select_from_friends_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

class SelectMeetupDetailsViewState extends State<SelectMeetupDetailsView> {
  late final CreateNewMeetupBloc _createNewMeetupBloc;

  static const List<Color> circleColours = [
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.yellow,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.greenAccent
  ];

  static Map<Color, double> colorToHueMap = {
    Colors.teal: BitmapDescriptor.hueAzure,
    Colors.orange: BitmapDescriptor.hueOrange,
    Colors.blue: BitmapDescriptor.hueBlue,
    Colors.yellow: BitmapDescriptor.hueYellow,
    Colors.pinkAccent: BitmapDescriptor.hueRose,
    Colors.redAccent: BitmapDescriptor.hueRed,
    Colors.greenAccent: BitmapDescriptor.hueGreen,
  };

  DateTime earliestPossibleMeetupDateTime = DateTime.now().add(const Duration(hours: 3));

  List<String> selectedParticipants = List<String>.empty(growable: true);
  late DateTime selectedMeetupDate;

  // Map related data
  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();

  List<Color> usedColoursThusFar = [];
  bool isFirstTimeMapSetup = true;

  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  Timer? _debounce;

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
    return BlocBuilder<CreateNewMeetupBloc, CreateNewMeetupState>(
        builder: (context, state) {
          if (state is MeetupModified) {
            return SingleChildScrollView(
              child: Container(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: WidgetUtils.skipNulls([
                      _renderParticipantsView(state),
                      WidgetUtils.spacer(2.5),
                      Divider(color: Theme.of(context).primaryColor),
                      WidgetUtils.spacer(2.5),
                      _renderMeetupNameView(state),
                      _renderMeetupDateTime(state),
                      WidgetUtils.spacer(2.5),
                      _renderMeetupLocationNotAvailableTextIfNeeded(state),
                      WidgetUtils.spacer(5),
                      _renderMeetupLocation(state),
                      WidgetUtils.spacer(2.5),
                      _renderAvailabilitiesView(state),
                    ]),
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

  _renderAvailabilitiesView(MeetupModified state) {
    return Text("Yet to come baby");
  }

  _renderMeetupLocationNotAvailableTextIfNeeded(MeetupModified state) {
    if (state.locationId == null) {
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
  }

  _renderMeetupLocation(MeetupModified state) {
    _setupMap([...state.participantUserProfiles, widget.currentUserProfile], context);
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GoogleMap(
            onTap: (_) {
              // _goToLocationView(userProfile, context);
            },
            mapType: MapType.normal,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            markers: markers,
            circles: Set<Circle>.of(circles.values),
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            }
        ),
      ),
    );
  }

  // todo - DRY this up with what is there ins meetup_home_view.dart
  void _generateCircleAndMarkerForUserProfile(PublicUserProfile profile, BuildContext context) {
    final newCircleId = CircleId(profile.userId);
    final _random = new Random();
    var nextColour = circleColours[_random.nextInt(circleColours.length)];
    while (usedColoursThusFar.contains(nextColour)) {
      nextColour = circleColours[_random.nextInt(circleColours.length)];
    }
    usedColoursThusFar.add(nextColour);

    final Circle circle = Circle(
      circleId: newCircleId,
      strokeColor: nextColour,
      consumeTapEvents: true,
      onTap: () {
        // _goToLocationView(userProfile, context);
      },
      fillColor: nextColour.withOpacity(0.25),
      strokeWidth: 5,
      center: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      radius: profile.locationRadius!.toDouble(),
    );
    circles[newCircleId] = circle;

    markers.add(
      Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(colorToHueMap[nextColour]!),
        markerId: MarkerId(profile.userId),
        position: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      ),
    );
  }

  _setupMap(List<PublicUserProfile> users, BuildContext context) {
    markers.clear();
    circles.clear();
    usedColoursThusFar.clear();
    users.forEach((user) {
      _generateCircleAndMarkerForUserProfile(user, context);
    });

    _initialCameraPosition = CameraPosition(
        target: LocationUtils.computeCentroid(markers.toList().map((e) => e.position)),
        tilt: 0,
        zoom: LocationUtils.getZoomLevelMini(users.map((e) => e.locationRadius!).reduce(max).toDouble())
    );

    if (isFirstTimeMapSetup) {
      _snapCameraToMarkers();
    }

  }

  _snapCameraToMarkers() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(LocationUtils.generateBoundsFromMarkers(markers), 50));
  }



  _renderMeetupNameView(MeetupModified state) {
    return Column(
      children: [
        const Text("Meetup name", style: TextStyle(fontSize: 16),),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onChanged: (text) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                final currentState = _createNewMeetupBloc.state;
                if(currentState is MeetupModified) {
                  _createNewMeetupBloc.add(
                      NewMeetupChanged(
                        meetupName: text,
                        meetupTime: currentState.meetupTime,
                        locationId: currentState.locationId,
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
                  meetupName: currentState.meetupName,
                  meetupTime: selectedMeetupDate,
                  locationId: currentState.locationId,
                  meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
                  currentUserAvailabilities: currentState.currentUserAvailabilities,
                )
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
                  meetupName: currentState.meetupName,
                  meetupTime: selectedDate,
                  locationId: currentState.locationId,
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

  _renderParticipantsView(MeetupModified state) {
    if (state.participantUserProfiles.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: state.participantUserProfiles.map((e) => _renderParticipantCircleViewWithCloseButton(e)).toList(),
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

  Widget _renderParticipantCircleViewWithCloseButton(PublicUserProfile userProfile) {
    return CircleAvatar(
      radius: 30,
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: ImageUtils.getUserProfileImage(userProfile, 500, 500),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).primaryColor,
                child: GestureDetector(
                  onTap: () {
                    final updatedListAfterRemovingParticipant = [...selectedParticipants];
                    updatedListAfterRemovingParticipant.removeWhere((element) => element == userProfile.userId);
                    _updateBlocState(updatedListAfterRemovingParticipant);
                    _updateUserSearchResultsListIfNeeded(userProfile.userId);
                  },
                  child: Icon(
                    Icons.remove,
                    size: 20,
                    color: Colors.white,
                  ),
                )
            ),
          )
        ],
      ),
    );
  }

  _updateUserSearchResultsListIfNeeded(String userId) {
    selectFromFriendsViewStateGlobalKey.currentState?.makeUserListItemUnselected(userId);
  }

  _updateBlocState(List<String> participantUserIds) {
    final currentState = _createNewMeetupBloc.state;
    if (currentState is MeetupModified) {
      _createNewMeetupBloc.add(
          NewMeetupChanged(
              meetupName: currentState.meetupName,
              meetupTime: currentState.meetupTime,
              locationId: currentState.locationId,
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