import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef UpdateBlocCallback = void Function(LatLng coordinates, int radius);

class ProvideLocationView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radius;

  final UpdateBlocCallback updateBlocState;

  final double mapScreenHeightProportion;
  final double mapControlsHeightProportion;

  const ProvideLocationView({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.updateBlocState,
    this.mapScreenHeightProportion = 0.65,
    this.mapControlsHeightProportion = 0.2
  }): super(key: key);


  @override
  State createState() {
    return ProvideLocationViewState();
  }
}

class ProvideLocationViewState extends State<ProvideLocationView> {
  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  CircleId circleId = const CircleId('radius_circle');

  final Completer<GoogleMapController> _controller = Completer();
  late final CameraPosition initialCameraPosition;

  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  late double currentSliderValue;
  late LatLng currentCentrePosition;


  @override
  void initState() {
    super.initState();
   _setupMap();
  }

  _setupMap() {
    currentSliderValue = widget.radius / 1000;
    currentCentrePosition = LatLng(widget.latitude, widget.longitude);
    initialCameraPosition =  CameraPosition(
        target: currentCentrePosition,
        zoom: LocationUtils.getZoomLevel(widget.radius)
    );
    _generateBoundaryCircle();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentCentrePosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    KeyboardUtils.hideKeyboard(context);
    return Column(
      children: [
        _renderMap(),
        _renderMapControls(),
      ],
    );
  }

  _renderMap() {
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * widget.mapScreenHeightProportion,
      child: GoogleMap(
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
      ),
    );
  }

  _onCameraMove(CameraPosition cameraPosition) {
    setState(() {
      currentCentrePosition = cameraPosition.target;
      markers.clear();
      markers.add(Marker(
        markerId: MarkerId("camera_centre_marker_id-${DateTime.now().millisecondsSinceEpoch}"),
        position: currentCentrePosition,
      ));
      _generateBoundaryCircle();
      widget.updateBlocState(currentCentrePosition, (currentSliderValue * 1000).toInt());
    });
  }

  void _generateBoundaryCircle() {
    circles.clear();
    final Circle circle = Circle(
      circleId: circleId,
      consumeTapEvents: true,
      strokeColor: Colors.tealAccent,
      fillColor: Colors.teal.withOpacity(0.5),
      strokeWidth: 5,
      center: currentCentrePosition,
      radius: currentSliderValue * 1000,
    );
    setState(() {
      circles[circleId] = circle;
    });
  }

  _renderMapControls() {
    return SizedBox(
      height: ScreenUtils.getScreenHeight(context) * widget.mapControlsHeightProportion,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: const Text("Select your radius of discovery",
                  style: TextStyle(fontSize: 16),
                ),
              )
          ),
          Slider(
            value: currentSliderValue,
            divisions: 50,
            max: 50.0,
            min: 1.0,
            label: currentSliderValue.round().toString(),
            onChanged: (value) {
              setState(() {
                currentSliderValue = value.round().toDouble();
                _generateBoundaryCircle();
                widget.updateBlocState(currentCentrePosition, (currentSliderValue * 1000).toInt());
              });
            },
          ),
          Expanded(
              child: Text("$currentSliderValue km")
          ),
        ],
      ),
    );
  }
}