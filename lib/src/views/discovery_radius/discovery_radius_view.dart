import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/discovery_radius/bloc/discovery_radius_bloc.dart';
import 'package:flutter_app/src/views/discovery_radius/bloc/discovery_radius_event.dart';
import 'package:flutter_app/src/views/discovery_radius/bloc/discovery_radius_state.dart';
import 'package:flutter_app/src/views/shared_components/provide_location_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DiscoveryRadiusView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radius;
  final AuthenticatedUser user;

  const DiscoveryRadiusView({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.user,
  }): super(key: key);

  static Route route(double latitude, double longitude, double radius, AuthenticatedUser user) {
    return MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<DiscoveryRadiusBloc>(
                  create: (context) => DiscoveryRadiusBloc(
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                    authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
                  )
              ),
            ],
            child: DiscoveryRadiusView(latitude: latitude, longitude: longitude, radius: radius, user: user)
        )
    );
  }

  @override
  State createState() {
    return DiscoveryRadiusViewState();
  }
}

class DiscoveryRadiusViewState extends State<DiscoveryRadiusView> {
  late DiscoveryRadiusBloc _discoveryRadiusBloc;

  @override
  void initState() {
    super.initState();
    _discoveryRadiusBloc = BlocProvider.of<DiscoveryRadiusBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discovery Radius", style: TextStyle(color: Colors.teal)),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _onFloatingActionButtonPress,
          backgroundColor: Colors.teal,
          child: const Icon(Icons.save, color: Colors.white)
      ),
      body: BlocListener<DiscoveryRadiusBloc, DiscoveryRadiusState>(
        listener: (context, state) {
          if (state is LocationInfoUpdated) {
            SnackbarUtils.showSnackBar(context, "Discovery radius updated successfully!");
            Navigator.pop(context);
          }
        },
        child: ProvideLocationView(
            latitude: widget.latitude,
            longitude: widget.longitude,
            radius: widget.radius,
            updateBlocState: _updateBlocState
        ),
      ),
    );
  }

  _onFloatingActionButtonPress() {
    final currentState = _discoveryRadiusBloc.state;
    if (currentState is LocationInfoModified) {
      _discoveryRadiusBloc.add(
          LocationInfoSubmitted(
            user: currentState.user,
            coordinates: currentState.selectedCoordinates,
            radius: currentState.radius,
          )
      );
    }
  }

  _updateBlocState(LatLng coordinates, int radius) {
    _discoveryRadiusBloc.add(
        LocationInfoChanged(
          user: widget.user,
          coordinates: coordinates,
          radius: radius,
        )
    );
  }
}