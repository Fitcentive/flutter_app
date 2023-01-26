import 'dart:async';

import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/location_card_view.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_bloc.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_event.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

typedef UpdateSelectedGymLocationBlocCallback = void Function(String locationId);

// todo - ensure this is also used when searching for gyms to schedule workouts with
class SearchLocationsView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radiusInMetres;

  final UpdateSelectedGymLocationBlocCallback updateBlocState;

  final double mapScreenHeightProportion;
  final double mapControlsHeightProportion;

  const SearchLocationsView({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.radiusInMetres,
    required this.updateBlocState,
    this.mapScreenHeightProportion = 0.78,
    this.mapControlsHeightProportion = 0.2
  }): super(key: key);

  static Widget withBloc({
    required double latitude,
    required double longitude,
    required double radius,
    required UpdateSelectedGymLocationBlocCallback updateBlocCallback,
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
        latitude: latitude,
        longitude: longitude,
        radiusInMetres: radius,
        updateBlocState: updateBlocCallback,
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
  static const String circleIdString = "radius_circle";

  MarkerId markerId = const MarkerId(currentLocationMarkerId);
  CircleId circleId = const CircleId(circleIdString);

  late final SearchLocationsBloc _searchLocationsBloc;

  final Completer<GoogleMapController> _mapController = Completer();
  final PanelController _slidingUpPanelController = PanelController();
  late final CameraPosition initialCameraPosition;

  bool shouldCameraSnapToMarkers = true;
  bool shouldCurrentPositionBeUpdatedWithCameraPosition = false;
  int currentSelectedGymIndex = 0;

  late LatLng currentCentrePosition;
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late BitmapDescriptor customGymLocationIcon;
  late BitmapDescriptor customGymLocationSelectedIcon;
  CarouselController buttonCarouselController = CarouselController();

  @override
  void initState() {
    super.initState();

    _setupMap();
    _searchLocationsBloc = BlocProvider.of<SearchLocationsBloc>(context);

    _initiateLocationSearchAroundCoordinates(widget.latitude, widget.longitude, List.empty());
  }

  void _generateBoundaryCircle() {
    circles.clear();
    final Circle circle = Circle(
      circleId: circleId,
      consumeTapEvents: false,
      strokeColor: Colors.tealAccent,
      fillColor: Colors.teal.withOpacity(0.5),
      strokeWidth: 5,
      center: currentCentrePosition,
      radius: widget.radiusInMetres,
    );
    circles[circleId] = circle;
  }

  _setupMap() async {
    currentCentrePosition = LatLng(widget.latitude, widget.longitude);
    initialCameraPosition =  CameraPosition(
        target: currentCentrePosition,
        zoom: LocationUtils.getZoomLevel(widget.radiusInMetres)
    );
    _generateBoundaryCircle();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentCentrePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
      ),
    );
    final Uint8List? gymMarkerIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon.png', 100);
    final Uint8List? gymMarkerSelectedIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon_selected.png', 100);

    customGymLocationIcon = BitmapDescriptor.fromBytes(gymMarkerIcon!);
    customGymLocationSelectedIcon = BitmapDescriptor.fromBytes(gymMarkerSelectedIcon!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchLocationsBloc, SearchLocationsState>(
        builder: (context, state) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                if (state is FetchLocationsAroundCoordinatesLoaded &&
                    state.coordinates.latitude != currentCentrePosition.latitude &&
                    state.coordinates.longitude != currentCentrePosition.longitude) {
                  shouldCameraSnapToMarkers = true;
                  shouldCurrentPositionBeUpdatedWithCameraPosition = false;
                  _initiateLocationSearchAroundCoordinates(
                      currentCentrePosition.latitude,
                      currentCentrePosition.longitude,
                      state.locationResults,
                  );
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.search, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            body: Column(
              children: [
                _renderHelpText(),
                WidgetUtils.spacer(2.5),
                _renderMap(state),
              ],
            ),
          );
        }
    );
  }

  _renderHelpText() {
    return const Text(
        "Long press on map to unlock viewing radius. Long press again to lock",
      style: TextStyle(fontSize: 11),
    );
  }

  _slideUpPanelGymOptions(SearchLocationsState state) {
    if (state is FetchLocationsAroundCoordinatesLoaded) {
      if (_slidingUpPanelController.isAttached) {
        _slidingUpPanelController.show();
      }
      return CarouselSlider(
          items: state.locationResults.map((e) =>
              LocationCardView(
                  locationId: e.locationId,
                  location: e.location,
              )
          ).toList(),
          carouselController: buttonCarouselController,
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
              widget.updateBlocState(state.locationResults[currentSelectedGymIndex].locationId);

              // todo - make position marker draggable and simply the whole lock/unlock camera pan flow
              final relevantLocationItem = state.locationResults[currentSelectedGymIndex];
              final GoogleMapController controller = await _mapController.future;
              controller
                  .animateCamera(CameraUpdate.newLatLng(relevantLocationItem.location.geocodes.toGoogleMapsLatLng()));
            },
            scrollDirection: Axis.horizontal,
          )
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

  LatLngBounds _bounds(Set<Marker> markers) {
    return _createBounds(markers.map((m) => m.position).toList());
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions.map((p) => p.latitude).reduce((value, element) => value < element ? value : element); // smallest
    final southwestLon = positions.map((p) => p.longitude).reduce((value, element) => value < element ? value : element);
    final northeastLat = positions.map((p) => p.latitude).reduce((value, element) => value > element ? value : element); // biggest
    final northeastLon = positions.map((p) => p.longitude).reduce((value, element) => value > element ? value : element);
    return LatLngBounds(
        southwest: LatLng(southwestLat, southwestLon),
        northeast: LatLng(northeastLat, northeastLon)
    );
  }

  _snapCameraToMarkers() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(_bounds(markers), 50));
  }

  _renderMap(SearchLocationsState state) {
    _generateBoundaryCircle();
    if (state is FetchLocationsAroundCoordinatesLoaded) {
      markers.removeWhere((element) => element.markerId.value != currentLocationMarkerId);
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
                buttonCarouselController.jumpToPage(currentSelectedGymIndex);
                widget.updateBlocState(location.locationId);
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
            SlidingUpPanel(
              slideDirection: SlideDirection.UP,
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
        onLongPress: (latlng) {
          shouldCurrentPositionBeUpdatedWithCameraPosition = !shouldCurrentPositionBeUpdatedWithCameraPosition;
        },
        // onCameraIdle: _onCameraIdle,
      ),
    );
  }

  _initiateLocationSearchAroundCoordinates(double latitude, double longitude, List<Location> previousLocationResults) {
    _searchLocationsBloc.add(
        FetchLocationsAroundCoordinatesRequested(
            query: "gym",
            coordinates: Coordinates(latitude, longitude),
            radiusInMetres: widget.radiusInMetres.toInt(),
            previousLocationResults: previousLocationResults
        )
    );
  }

  _onCameraMove(CameraPosition cameraPosition) {
    setState(() {
      shouldCameraSnapToMarkers = false;
      // this should only happen on certain occasions
      if (shouldCurrentPositionBeUpdatedWithCameraPosition) {
        currentCentrePosition = cameraPosition.target;
      }
      markers.removeWhere((element) => element.markerId.value == currentLocationMarkerId);
      markers.add(Marker(
        markerId: const MarkerId(currentLocationMarkerId),
        position: currentCentrePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
      _generateBoundaryCircle();
      // widget.updateBlocState(currentCentrePosition, (currentSliderValue * 1000).toInt());
    });
  }

}