import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_bloc.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_event.dart';
import 'package:flutter_app/src/views/shared_components/search_locations/bloc/search_locations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef UpdateBlocCallback = void Function();

// todo - ensure this is also used when searching for gyms to schedule workouts with
class SearchLocationsView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radius;

  final UpdateBlocCallback updateBlocState;

  final double mapScreenHeightProportion;
  final double mapControlsHeightProportion;

  const SearchLocationsView({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.updateBlocState,
    this.mapScreenHeightProportion = 0.65,
    this.mapControlsHeightProportion = 0.2
  }): super(key: key);

  static Widget withBloc({
    required double latitude,
    required double longitude,
    required double radius,
    required UpdateBlocCallback updateBlocCallback,
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
        radius: radius,
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

  final Completer<GoogleMapController> _controller = Completer();
  late final CameraPosition initialCameraPosition;
  bool isCameraMoving = false;

  late LatLng currentCentrePosition;
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late BitmapDescriptor customGymLocationIcon;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _setupMap();
    _searchLocationsBloc = BlocProvider.of<SearchLocationsBloc>(context);
    _searchLocationsBloc.add(
        FetchLocationsAroundCoordinatesRequested(
          query: "gym",
          coordinates: Coordinates(widget.latitude, widget.longitude),
          radiusInMetres: widget.radius.toInt()
        )
    );
  }

  // todo - why is this not being generated properly??
  // todo - add slidign up listview with carousel of gyms
  void _generateBoundaryCircle() {
    circles.clear();
    final Circle circle = Circle(
      circleId: circleId,
      consumeTapEvents: false,
      strokeColor: Colors.red,
      fillColor: Colors.red.withOpacity(1),
      strokeWidth: 5,
      center: currentCentrePosition,
      radius: widget.radius * 1000,
    );
    circles[circleId] = circle;
  }

  _setupMap() async {
    currentCentrePosition = LatLng(widget.latitude, widget.longitude);
    initialCameraPosition =  CameraPosition(
        target: currentCentrePosition,
        zoom: LocationUtils.getZoomLevelDetail(widget.radius)
    );
    _generateBoundaryCircle();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentCentrePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
      ),
    );
    final Uint8List? markerIcon = await ImageUtils.getBytesFromAsset('assets/icons/gym_location_icon.png', 100);
    customGymLocationIcon = BitmapDescriptor.fromBytes(markerIcon!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchLocationsBloc, SearchLocationsState>(
        builder: (context, state) {
          return Column(
            children: [
              _renderSearchBar(),
              _renderMap(state),
            ],
          );
        }
    );
  }

  Widget _renderSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: ListTile(
        trailing: IconButton(
          icon: const Icon(
            Icons.search,
            color: Colors.teal,
            size: 28,
          ),
          onPressed: () {
            _searchLocationsBloc.add(
                SearchLocationsQuerySubmitted(
                  query: _textEditingController.value.text,
                  coordinates: Coordinates(currentCentrePosition.latitude, currentCentrePosition.longitude),
                  radiusInMetres: widget.radius.toInt()
                )
            );
          },
        ),
        title: TextField(
          controller: _textEditingController,
          onSubmitted: (value) {
            _searchLocationsBloc.add(
                SearchLocationsQueryChanged(
                    query: value,
                    coordinates: Coordinates(currentCentrePosition.latitude, currentCentrePosition.longitude),
                    radiusInMetres: widget.radius.toInt()
                )
            );
          },
          onChanged: (value) {
            _searchLocationsBloc.add(
                SearchLocationsQueryChanged(
                    query: value,
                    coordinates: Coordinates(currentCentrePosition.latitude, currentCentrePosition.longitude),
                    radiusInMetres: widget.radius.toInt()
                )
            );
          },
          decoration: const InputDecoration(
            hintText: 'Search by gym name...',
            hintStyle: TextStyle(
              // color: Colors.white,
              fontSize: 15,
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  _showProgressIndicatorIfNeeded(SearchLocationsState state) {
    if (state is FetchLocationsAroundCoordinatesLoading) {
      return const Center(
        child: Opacity(opacity: 0.5, child: CircularProgressIndicator()),
      );
    }
    return null;
  }

  _renderMap(SearchLocationsState state) {
    _generateBoundaryCircle();
    if (state is FetchLocationsAroundCoordinatesLoaded) {
      state.locationResults.forEach((location) {
        markers.add(
          Marker(
              markerId: MarkerId(location.fsqId),
              position: location.geocodes.toGoogleMapsLatLng(),
              icon: customGymLocationIcon,
              onTap: () {
              // todo - fill this in
            }
          ),
        );
      });
    }
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * widget.mapScreenHeightProportion,
      child: Stack(
        children: WidgetUtils.skipNulls([
          _showMap(),
          _showProgressIndicatorIfNeeded(state),
        ]),
      ),
    );
  }

  _showMap() {
    return GoogleMap(
      mapType: MapType.hybrid,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      initialCameraPosition: initialCameraPosition,
      circles: Set<Circle>.of(circles.values),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      markers: markers,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
    );
  }

  _onCameraIdle() {
    // Transitioning from moving camera to static
    final currentState = _searchLocationsBloc.state;
    if (isCameraMoving) {
      if (currentState is FetchLocationsAroundCoordinatesLoaded &&
          currentState.coordinates.latitude != currentCentrePosition.latitude &&
          currentState.coordinates.longitude != currentCentrePosition.longitude
      ) {
        _searchLocationsBloc.add(
            FetchLocationsAroundCoordinatesRequested(
                query: "gym",
                coordinates: Coordinates(currentCentrePosition.latitude, currentCentrePosition.longitude),
                radiusInMetres: widget.radius.toInt()
            )
        );
      }
    }
    isCameraMoving = false;
  }

  _onCameraMove(CameraPosition cameraPosition) {
    setState(() {
      isCameraMoving = true;
      currentCentrePosition = cameraPosition.target;
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