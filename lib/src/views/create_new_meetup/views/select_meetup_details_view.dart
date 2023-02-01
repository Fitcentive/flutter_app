import 'dart:async';
import 'dart:math';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_participants_list.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/search_locations_view.dart';
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

class SelectMeetupDetailsViewState extends State<SelectMeetupDetailsView> with AutomaticKeepAliveClientMixin {
  final String customSelectedLocationMarkerId = "customSelectedLocationMarkerId";

  late final CreateNewMeetupBloc _createNewMeetupBloc;

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
  BitmapDescriptor? customGymLocationIcon;

  @override
  bool get wantKeepAlive => true;

  _setupIcons() async {
    if (customGymLocationIcon == null) {
      final Uint8List? gymMarkerIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon.png', 100);
      customGymLocationIcon = BitmapDescriptor.fromBytes(gymMarkerIcon!);
    }
  }

  @override
  void initState() {
    super.initState();
    _createNewMeetupBloc = BlocProvider.of<CreateNewMeetupBloc>(context);

    _setupIcons();

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
            updateBlocCallback: (location) {
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
            }),
            (route) => true
    );

  }

  _renderMeetupLocation(MeetupModified state) {
    _setupMap(state, [...state.participantUserProfiles, widget.currentUserProfile]);
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * 0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GoogleMap(
            onTap: (_) {
              _goToSelectLocationRoute(state, context);
            },
            mapType: MapType.normal,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            markers: markers,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            circles: Set<Circle>.of(circles.values),
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>> {
              Factory<OneSequenceGestureRecognizer> (() => EagerGestureRecognizer()),
            }
        ),
      ),
    );
  }

  void _generateCircleAndMarkerForUserProfile(
      MeetupModified state,
      PublicUserProfile profile,
      BitmapDescriptor markerIcon
  ) {
    // circles.clear();
    final newCircleId = CircleId(profile.userId);
    final Circle circle = Circle(
      circleId: newCircleId,
      strokeColor: state.userIdToColorSet[profile.userId]!,
      consumeTapEvents: false,
      onTap: () {
        // _goToLocationView(userProfile, context);
      },
      fillColor: state.userIdToColorSet[profile.userId]!.withOpacity(0.25),
      strokeWidth: 5,
      center: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      radius: profile.locationRadius!.toDouble(),
    );
    circles[newCircleId] = circle;

    markers.add(
      Marker(
        icon: markerIcon,
        markerId: MarkerId(profile.userId),
        position: LatLng(profile.locationCenter!.latitude, profile.locationCenter!.longitude),
      ),
    );
  }

  // todo - DRY this up with what is there ins meetup_home_view.dart
   _setupMap(MeetupModified state, List<PublicUserProfile> users) {
     _setupIcons();
     for (var user in users) {
       final BitmapDescriptor theCustomMarkerToUse = state.userIdToMapMarkerIconSet[user.userId]!;
       _generateCircleAndMarkerForUserProfile(state, user, theCustomMarkerToUse);
     }

     markers.removeWhere((element) => element.markerId.value == customSelectedLocationMarkerId);
     if (state.location != null) {
       markers.add(
         Marker(
           icon: customGymLocationIcon!,
           markerId: MarkerId(customSelectedLocationMarkerId),
           position: state.location!.location.geocodes.toGoogleMapsLatLng(),
         ),
       );
     }

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
      return MeetupParticipantsList(
          participantUserProfiles: state.participantUserProfiles,
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