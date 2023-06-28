import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/shared_components/custom_sliding_up_panel.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/models/user_profile_with_location.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/foursquare_location_card_view.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_bloc.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_event.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

typedef UpdateSelectedGymLocationBlocCallback = void Function(Location location);

class SearchLocationsView extends StatefulWidget {
  static const String routeName = 'search-locations';

  final String? initialSelectedLocationId;
  final String? initialSelectedLocationFsqId;

  final List<UserProfileWithLocation> userProfilesWithLocations;

  final UpdateSelectedGymLocationBlocCallback updateBlocState;

  final double mapScreenHeightProportion;
  final double mapControlsHeightProportion;

  final bool isRoute;

  const SearchLocationsView({
    Key? key,
    required this.userProfilesWithLocations,
    required this.initialSelectedLocationId,
    required this.initialSelectedLocationFsqId,
    required this.updateBlocState,
    required this.isRoute,
    this.mapScreenHeightProportion = 0.78,
    this.mapControlsHeightProportion = 0.2
  }): super(key: key);

  static Route route({
    required List<UserProfileWithLocation> userProfilesWithLocations,
    required String? initialSelectedLocationId,
    required String? initialSelectedLocationFsqId,
    required UpdateSelectedGymLocationBlocCallback updateBlocCallback,
    Key? key,
  }) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => SearchLocationsView.withBloc(
            userProfilesWithLocations: userProfilesWithLocations,
            initialSelectedLocationId: initialSelectedLocationId,
            initialSelectedLocationFsqId: initialSelectedLocationFsqId,
            updateBlocCallback: updateBlocCallback,
            isRoute: true,
        )
    );
  }


  static Widget withBloc({
    required List<UserProfileWithLocation> userProfilesWithLocations,
    required String? initialSelectedLocationId,
    required String? initialSelectedLocationFsqId,
    required UpdateSelectedGymLocationBlocCallback updateBlocCallback,
    bool isRoute = false,
    Key? key,
    }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SearchLocationsBloc>(
            create: (context) => SearchLocationsBloc(
              meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: SearchLocationsView(
        initialSelectedLocationId: initialSelectedLocationId,
        initialSelectedLocationFsqId: initialSelectedLocationFsqId,
        userProfilesWithLocations: userProfilesWithLocations,
        updateBlocState: updateBlocCallback,
        isRoute: isRoute,
      ),
    );
  }


  @override
  State createState() {
    return SearchLocationsViewState();
  }
}

class SearchLocationsViewState extends State<SearchLocationsView> {
  static const String currentLocationMarkerId = "camera_centre_marker_id";
  static const int defaultLocationSearchQuerySearchRadiusInMetres = 10000;  // todo - avoid hardcoding radius

  bool isPremiumEnabled = false;

  Map<String, BitmapDescriptor?> userIdToMapMarkerIcon = {};
  Map<String, Color> userIdToMapMarkerColor = {};

  late final SearchLocationsBloc _searchLocationsBloc;

  final Completer<GoogleMapController> _mapController = Completer();
  final PanelController _slidingUpPanelController = PanelController();
  late final CameraPosition initialCameraPosition;

  bool shouldCameraSnapToMarkers = true;
  bool shouldCurrentPositionBeUpdatedWithCameraPosition = false;
  int currentSelectedGymIndex = 0;

  bool isInitialSetupOfMap = true;
  List<Color> usedColoursThusFar = [];

  late LatLng currentCentrePosition;
  late LatLng currentCameraCentrePosition;
  late double minimumRadiusOfAllInvolved;
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late BitmapDescriptor customGymLocationIcon;
  late BitmapDescriptor customGymLocationSelectedIcon;
  CarouselController gymsCarouselController = CarouselController();

  bool isCameraUpdateHappening = false;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupColorsForUsers();
    isPremiumEnabled = WidgetUtils.isPremiumEnabledForUser(context);
    widget.userProfilesWithLocations.forEach((e) => userIdToMapMarkerIcon[e.currentUserProfile.userId] = null);

    _setupMap(widget.userProfilesWithLocations.map((e) => e.currentUserProfile).toList());
    _searchLocationsBloc = BlocProvider.of<SearchLocationsBloc>(context);

    minimumRadiusOfAllInvolved = widget.userProfilesWithLocations.map((e) => e.radiusInMetres).reduce(min);

    // search around centroid of coordinates instead?
    if (widget.userProfilesWithLocations.isNotEmpty){
      if (widget.userProfilesWithLocations.length == 1) {
        _initiateLocationSearchAroundCoordinates(
            widget.userProfilesWithLocations.first.latitude,
            widget.userProfilesWithLocations.first.longitude,
            minimumRadiusOfAllInvolved.toInt(),
            List.empty()
        );
      }
      else {
        final latLngPoints = widget.userProfilesWithLocations.map((e) => LatLng(e.latitude, e.longitude));
        final center = LocationUtils.computeCentroid(latLngPoints);
        _initiateLocationSearchAroundCoordinates(
            center.latitude,
            center.longitude,
            minimumRadiusOfAllInvolved.toInt(),
            List.empty()
        );
      }
    }

  }

  _setupColorsForUsers() {
    widget.userProfilesWithLocations.map((e) => e.currentUserProfile).forEach((u) {
      var nextColor = userIdToMapMarkerColor[u.userId];

      if (nextColor == null) {
        final _random = Random();
        var nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
        while (usedColoursThusFar.contains(nextColour)) {
          nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
        }
        userIdToMapMarkerColor[u.userId] = nextColour;
      }
    });
  }

  void _generateCircleAndMarkerForUserProfile(PublicUserProfile profile, BitmapDescriptor markerIcon) {
    final newCircleId = CircleId(profile.userId);
    final Circle circle = Circle(
      circleId: newCircleId,
      strokeColor: userIdToMapMarkerColor[profile.userId]!,
      consumeTapEvents: false,
      onTap: () {
        // _goToLocationView(userProfile, context);
      },
      fillColor: userIdToMapMarkerColor[profile.userId]!.withOpacity(0.25),
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

  _setupMap(List<PublicUserProfile> users) async {
    markers.clear();
    circles.clear();
    if (DeviceUtils.isAppRunningOnMobileBrowser()) {
      users.asMap().forEach((index, user) async {
        final BitmapDescriptor theCustomMarkerToUse = userIdToMapMarkerIcon[user.userId] ?? ColorUtils.markerList[index];
        _generateCircleAndMarkerForUserProfile(user, theCustomMarkerToUse);
      });
    }
    else {
      users.forEach((user) async {
        final BitmapDescriptor theCustomMarkerToUse = userIdToMapMarkerIcon[user.userId] ?? await  _generateCustomMarkerForUser(user);
        _generateCircleAndMarkerForUserProfile(user, theCustomMarkerToUse);
      });
    }

    currentCentrePosition =
        LocationUtils.computeCentroid(widget.userProfilesWithLocations.map((e) => LatLng(e.latitude, e.longitude)));
    currentCameraCentrePosition = currentCentrePosition;
    initialCameraPosition = CameraPosition(
        target: currentCentrePosition,
        tilt: 0,
        zoom: LocationUtils.getZoomLevel(users.map((e) => e.locationRadius!).reduce(min).toDouble())
    );

    if (DeviceUtils.isAppRunningOnMobileBrowser()) {
      customGymLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      customGymLocationSelectedIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
    else {
      final Uint8List? gymMarkerIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon.png', 100);
      final Uint8List? gymMarkerSelectedIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon_selected.png', 100);
      customGymLocationIcon = BitmapDescriptor.fromBytes(gymMarkerIcon!);
      customGymLocationSelectedIcon = BitmapDescriptor.fromBytes(gymMarkerSelectedIcon!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchLocationsBloc, SearchLocationsState>(
      listener: (context, state) {
        _selectInitialLocation();
      },
      child: BlocBuilder<SearchLocationsBloc, SearchLocationsState>(
          builder: (context, state) {
            return Scaffold(
              appBar: !widget.isRoute ? null : AppBar(
                title: const Text("Search Locations", style: TextStyle(color: Colors.teal),),
                iconTheme: const IconThemeData(
                  color: Colors.teal,
                ),
              ),
              body: Stack(
                children: WidgetUtils.skipNulls([
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: WidgetUtils.skipNulls([
                        _renderSearchTextBar(),
                        WidgetUtils.spacer(2.5),
                        _renderHelpText(),
                        WidgetUtils.spacer(2.5),
                        Stack(
                            children: [
                              _renderMap(state),
                              _recenterButton(),
                            ]
                        )
                        // Expanded(
                        //     child: _renderMap(state)
                        // ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FloatingActionButton(
                        heroTag: "SearchLocationsViewFab",
                        onPressed: () {
                          if (state is FetchLocationsAroundCoordinatesLoaded &&
                              state.coordinates.latitude != currentCentrePosition.latitude &&
                              state.coordinates.longitude != currentCentrePosition.longitude) {
                            shouldCameraSnapToMarkers = true;
                            shouldCurrentPositionBeUpdatedWithCameraPosition = false;
                            // todo - change this behaviour to be more consistent?
                            _initiateLocationSearchAroundCoordinates(
                              currentCentrePosition.latitude,
                              currentCentrePosition.longitude,
                              minimumRadiusOfAllInvolved.toInt(),
                              state.locationResults,
                            );
                          }
                        },
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                  !widget.isRoute ? null : Padding( // Only render tick button button if it is a route and not a component
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 5),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FloatingActionButton(
                        heroTag: "SearchLocationsViewSelectFab",
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }
      ),
    );
  }

  Widget _recenterButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: SizedBox(
          height: 40,
          width: 40,
          child: FloatingActionButton(
              heroTag: "MeetupLocationViewSnapToMarkersButton-${StringUtils.generateRandomString(10)}",
              onPressed: () {
                _snapCameraToMarkers();
              },
              backgroundColor: Colors.teal,
              tooltip: "Re-center",
              child: const Icon(
                  Icons.location_searching_outlined,
                  color: Colors.white,
                  size: 16
              )
          ),
        ),
      ),
    );
  }

  _selectInitialLocation() {
    final currentState = _searchLocationsBloc.state;
    if (currentState is FetchLocationsAroundCoordinatesLoaded) {
      // Select previously selected gym, if any
      // Need to only do this once!
      setState(() {
        if (isInitialSetupOfMap) {
          isInitialSetupOfMap = false;
          // Returns -1 if initialSelectedLocationId is NOT available
          // If that is the case, we re-fetch it and add it
          if (widget.initialSelectedLocationFsqId != null) {
            final indexOfInitiallySelectedLocationId = currentState.locationResults.indexWhere((element) => element.locationId == widget.initialSelectedLocationId);

            if (indexOfInitiallySelectedLocationId != -1) {
              currentSelectedGymIndex = indexOfInitiallySelectedLocationId;
            }
            else {
              // Else we re-fetch the specified location and add to results
              _searchLocationsBloc.add(
                  FetchLocationsByFsqId(
                      fsqId: widget.initialSelectedLocationFsqId!,
                      query: currentState.query,
                      coordinates: currentState.coordinates,
                      previousLocationResults: currentState.locationResults,
                      radiusInMetres: currentState.radiusInMetres
                  )
              );

              isInitialSetupOfMap = true;
            }
          }

        }
      });
      gymsCarouselController.onReady.then((value) => gymsCarouselController.jumpToPage(currentSelectedGymIndex));
      _slidingUpPanelController.open();
    }

  }

  _goToAccountDetailsView() {
    Navigator.pushReplacement(
      context,
      HomePage.route(defaultSelectedTab: HomePageState.accountDetails),
    );
  }

  _renderSearchTextBar() {
    return GestureDetector(
      onTap: () {
        if (!isPremiumEnabled) {
          WidgetUtils.showUpgradeToPremiumDialog(context, _goToAccountDetailsView);
        }
      },
      child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: TypeAheadField<PublicUserProfile>(
              suggestionsBoxController: _suggestionsController,
              debounceDuration: const Duration(milliseconds: 300),
              textFieldConfiguration: TextFieldConfiguration(
                  onSubmitted: (value) {},
                  autocorrect: false,
                  onTap: () => _suggestionsController.toggle(),
                  onChanged: (text) {},
                  enabled: isPremiumEnabled,
                  autofocus: true,
                  controller: _searchTextController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: "Search by location name",
                    prefixIcon: IconButton(
                      onPressed: () {
                        _suggestionsController.close();
                        setState(() {
                          _searchTextController.text = "";
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _suggestionsController.close();
                        // Make the search happen now
                        final currentState = _searchLocationsBloc.state;
                        if (currentState is FetchLocationsAroundCoordinatesLoaded) {
                          shouldCameraSnapToMarkers = true;
                          shouldCurrentPositionBeUpdatedWithCameraPosition = false;
                          _searchLocationsBloc.add(FetchLocationsAroundCoordinatesRequested(
                            query: _searchTextController.value.text,
                            coordinates: Coordinates(currentCameraCentrePosition.latitude, currentCameraCentrePosition.longitude),
                            radiusInMetres: defaultLocationSearchQuerySearchRadiusInMetres,
                            previousLocationResults: currentState.locationResults,
                          )
                          );
                        }
                      },
                      icon: const Icon(Icons.search),
                    ),
                  )),
              suggestionsCallback: (text)  {
                if (text.trim().isNotEmpty) {
                  // Do nothing?
                }
                return List.empty();
              },
              itemBuilder: (context, suggestion) {
                final s = suggestion;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: ImageUtils.getUserProfileImage(suggestion, 100, 100),
                      ),
                    ),
                  ),
                  title: Text("${s.firstName ?? ""} ${s.lastName ?? ""}"),
                  subtitle: Text(suggestion.username ?? ""),
                );
              },
              onSuggestionSelected: (suggestion) {},
              hideOnEmpty: true,
            )
        ),
    );
  }

  _renderHelpText() {
    if (shouldCurrentPositionBeUpdatedWithCameraPosition) {
      return Column(
        children: [
          const Text(
            "Long press on map to unlock viewing radius. Long press again to lock",
            style: TextStyle(fontSize: 11),
          ),
          WidgetUtils.spacer(2.5),
          const Text(
            "Viewing radius unlocked",
            style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    else {
      return const Text(
        "Long press on map to unlock viewing radius. Long press again to lock",
        style: TextStyle(fontSize: 11),
      );
    }

  }

  _slideUpPanelGymOptions(SearchLocationsState state) {
    if (state is FetchLocationsAroundCoordinatesLoaded) {
      if (_slidingUpPanelController.isAttached) {
        _slidingUpPanelController.show();
      }
      return PointerInterceptor(
        child: CarouselSlider(
            items: state.locationResults.map((e) =>
                FoursquareLocationCardView(
                    locationId: e.locationId,
                    location: e.location,
                )
            ).toList(),
            carouselController: gymsCarouselController,
            options: CarouselOptions(
              height: 300,
              // aspectRatio: 16/9,
              viewportFraction: 0.825,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              enlargeCenterPage: true,
              onPageChanged: (page, reason) async {
                currentSelectedGymIndex = page;
                widget.updateBlocState(state.locationResults[currentSelectedGymIndex]);

                final relevantLocationItem = state.locationResults[currentSelectedGymIndex];
                final GoogleMapController controller = await _mapController.future;
                controller
                    .animateCamera(CameraUpdate.newLatLng(relevantLocationItem.location.geocodes.toGoogleMapsLatLng()));
                isCameraUpdateHappening = true;
              },
              scrollDirection: Axis.horizontal,
            )
        ),
      );
    }
    else {
      if (_slidingUpPanelController.isAttached) {
        _slidingUpPanelController.hide();
      }
      return const Scaffold(body: Center(child: Text("Nothing here yet....")));
    }
  }

  _showProgressIndicatorIfNeeded(SearchLocationsState state) {
    if (state is FetchLocationsAroundCoordinatesLoading) {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, ScreenUtils.getScreenHeight(context) * 0.5/2),
        child: const Center(
          child: Opacity(opacity: 0.5, child: CircularProgressIndicator()),
        ),
      );
    }
    return null;
  }

  // todo - there is a bug in this somewhat, zoom level does not work too well
  _snapCameraToMarkers() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(LocationUtils.generateBoundsFromMarkers(markers), 50));
  }

  _renderMap(SearchLocationsState state) {
    if (state is FetchLocationsAroundCoordinatesLoaded) {
      // Remove all previously created nonUserLocationMarkers
      markers.removeWhere((element) => state.locationResults.map((e) => e.location.fsqId).contains(element.markerId.value));
      state.locationResults.asMap().forEach((index, location) {
        markers.add(
          Marker(
              markerId: MarkerId(location.location.fsqId),
              position: location.location.geocodes.toGoogleMapsLatLng(),
              icon: index == currentSelectedGymIndex ? customGymLocationSelectedIcon : customGymLocationIcon,
              onTap: () {
                final index = state.locationResults.indexWhere((element) => element.locationId == location.locationId);

                setState(() {
                  currentSelectedGymIndex = index;
                });
                gymsCarouselController.jumpToPage(currentSelectedGymIndex);
                _slidingUpPanelController.open();
                widget.updateBlocState(location);
            }
          ),
        );
      });

      if (shouldCameraSnapToMarkers) {
        _snapCameraToMarkers();
      }
    }

    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * widget.mapScreenHeightProportion,
      child: Stack(
        children: WidgetUtils.skipNulls([
          _showMap(context),
          _showProgressIndicatorIfNeeded(state),
            CustomSlidingUpPanel(
              height: ScreenUtils.getScreenHeight(context),
              width: min(ScreenUtils.getScreenWidth(context), ConstantUtils.WEB_APP_MAX_WIDTH),
              slideDirection: CustomSlideDirection.UP,
              color: Colors.transparent,
              controller: _slidingUpPanelController,
              minHeight: ScreenUtils.getScreenHeight(context) * 0.33,
              maxHeight: ScreenUtils.getScreenHeight(context) * 0.5,
              panel: _slideUpPanelGymOptions(state),
            )
        ]),
      ),
    );
  }

  _showMap(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, ScreenUtils.getScreenHeight(context) * 0.5/2),
      child: GoogleMap(
        mapType: MapType.hybrid,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: initialCameraPosition,
        circles: Set<Circle>.of(circles.values),
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        },
        markers: markers,
        onCameraMove: _onCameraMove,
        onCameraIdle: () {
          if (isCameraUpdateHappening){
            _slidingUpPanelController.open();
            isCameraUpdateHappening = false;
          }
        },
        onLongPress: (latlng) {
          setState(() {
            shouldCurrentPositionBeUpdatedWithCameraPosition = !shouldCurrentPositionBeUpdatedWithCameraPosition;
          });
        },
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())
        },
        // onCameraIdle: _onCameraIdle,
      ),
    );
  }

  _initiateLocationSearchAroundCoordinates(
      double latitude,
      double longitude,
      int radiusInMetres,
      List<Location> previousLocationResults
  ) {
    _searchLocationsBloc.add(
        FetchLocationsAroundCoordinatesRequested(
            query: "gym",
            coordinates: Coordinates(latitude, longitude),
            radiusInMetres: radiusInMetres,
            previousLocationResults: previousLocationResults
        )
    );
  }

  _generateCustomMarkerForUser(PublicUserProfile userProfile) async {
    final fullImageUrl = ImageUtils.getFullImageUrl(userProfile.photoUrl, 96, 96);
    final request = await http.get(Uri.parse(fullImageUrl));
    return await ImageUtils.getMarkerIcon(request.bodyBytes, const Size(96, 96), userIdToMapMarkerColor[userProfile.userId]!);
  }

  _onCameraMove(CameraPosition cameraPosition) async {
    setState(() {
      shouldCameraSnapToMarkers = false;

      currentCameraCentrePosition = cameraPosition.target;
      // this should only happen on certain occasions
      if (shouldCurrentPositionBeUpdatedWithCameraPosition) {
        currentCentrePosition = cameraPosition.target;
      }

      markers.removeWhere((element) => element.markerId.value == currentLocationMarkerId);
      markers.add(Marker(
        alpha: shouldCurrentPositionBeUpdatedWithCameraPosition ? 1.0 : 0.0,
        markerId: const MarkerId(currentLocationMarkerId),
        position: currentCentrePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    });
  }

}