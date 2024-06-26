import 'dart:async';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/image_picker/custom_image_picker.dart';
import 'package:flutter_app/src/infrastructure/permissions/location_permissions.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/authenticated_user_stream_repository.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_bloc.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_event.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_state.dart';
import 'package:flutter_app/src/views/discovery_radius/discovery_radius_view.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/manage_premium/manage_premium_view.dart';
import 'package:flutter_app/src/views/upgrade_to_premium/upgrade_to_premium_view.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:skeleton_loader/skeleton_loader.dart';
import 'package:tuple/tuple.dart';

class AccountDetailsView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final AuthenticatedUser authenticatedUser;

  const AccountDetailsView({
    Key? key,
    required this.currentUserProfile,
    required this.authenticatedUser
  }): super(key: key);

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      AuthenticatedUser authenticatedUser
      ) => MultiBlocProvider(
        providers: [
          BlocProvider<AccountDetailsBloc>(
              create: (context) => AccountDetailsBloc(
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    publicGatewayRepository: RepositoryProvider.of<PublicGatewayRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                    authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
                  )
          ),
        ],
        child: AccountDetailsView(currentUserProfile: currentUserProfile, authenticatedUser: authenticatedUser),
      );

  @override
  State createState() {
    return AccountDetailsViewState();
  }
}

class AccountDetailsViewState extends State<AccountDetailsView> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final CustomImagePicker _picker = CustomImagePicker();

  late AuthenticationBloc _authenticationBloc;
  late AccountDetailsBloc _accountDetailsBloc;

  late String selectedUserGender;

  CardFieldInputDetails? cardFieldInputDetails;
  bool isDialogShown = false;

  late int locationRadius;
  Position? currentUserLivePosition;
  late LatLng currentUserProfileLocationCenter;
  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _mapController = Completer();
  MarkerId markerId = const MarkerId("camera_centre_marker_id");
  CircleId circleId = const CircleId('radius_circle');
  final Set<Marker> markers = <Marker>{};
  final Map<CircleId, Circle> circles = <CircleId, Circle>{};

  @override
  void initState() {
    super.initState();
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _accountDetailsBloc = BlocProvider.of<AccountDetailsBloc>(context);

    _getUserCurrentPosition();

    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      _fillInUserProfileDetails(authState.authenticatedUser);
      _setupMap(authState.authenticatedUser);
      selectedUserGender = authState.authenticatedUser.userProfile?.gender ?? 'Other';

      _accountDetailsBloc.add(const TrackViewCurrentUserAccountDetailsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) async {
        if (state is AuthSuccessUserUpdateState) {
          _fillInUserProfileDetails(state.authenticatedUser);
          _setupMap(state.authenticatedUser);
          (await _mapController.future).moveCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
        }
      },
      child: BlocListener<AccountDetailsBloc, AccountDetailsState>(
        listener: (context, state) {
          if (state is AccountDetailsUpdatedSuccessfully) {
            SnackbarUtils.showSnackBar(context, "Profile updated successfully!");
            context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                user: state.user,
                firstName: state.firstName.value,
                lastName: state.lastName.value,
                photoUrl: state.photoUrl,
                gender: state.gender
            ));
          }
        },
        child: BlocBuilder<AccountDetailsBloc, AccountDetailsState>(builder: (context, state) {
          return Scaffold(
            floatingActionButton: _saveAccountDetailsButton(state),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _spacer(12),
                  _headerElement(state),
                  _spacer(12),
                  _fullLengthRowElement(_nameField("First Name", state)),
                  _spacer(6),
                  _fullLengthRowElement(_nameField("Last Name", state)),
                  _spacer(6),
                  _fullLengthRowElement( _emailWidget()),
                  _spacer(6),
                  _fullLengthRowElement(_usernameField()),
                  _spacer(12),
                  _fullLengthRowElement(_genderField(state)),
                  _spacer(6),
                  _fullLengthRowElement(_locationWidget()),
                  _spacer(12),
                  _deleteAccountButton(),
                  _spacer(40),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  _getUserCurrentPosition() async {
    final livePosition = await LocationPermissions.determinePosition();
    setState(() {
      currentUserLivePosition = livePosition;
    });
  }

  void _generateBoundaryCircle(LatLng position, int radius) {
    circles.clear();
    final Circle circle = Circle(
      circleId: circleId,
      strokeColor: Colors.tealAccent,
      consumeTapEvents: true,
      onTap: () {
        final currentState = _authenticationBloc.state;
        if (currentState is AuthSuccessUserUpdateState) {
          if (!isDialogShown) {
            _goToDiscoveryRadiusView(currentState);
          }
        }
      },
      fillColor: Colors.teal.withOpacity(0.5),
      strokeWidth: 5,
      center: position,
      radius: radius.toDouble(),
    );
    setState(() {
      circles[circleId] = circle;
    });
  }

  _setupMap(AuthenticatedUser user) {
    locationRadius = user.userProfile?.locationRadius ?? 1000;

    // Use user profile location - otherwise use live location - otherwise use default location
    currentUserProfileLocationCenter = user.userProfile?.locationCenter != null ?
    LatLng(user.userProfile!.locationCenter!.latitude, user.userProfile!.locationCenter!.longitude) :
    (currentUserLivePosition != null ? LatLng(currentUserLivePosition!.latitude, currentUserLivePosition!.longitude) :
    LocationUtils.defaultLocation);

    _initialCameraPosition = CameraPosition(
        target: currentUserProfileLocationCenter,
        tilt: 0,
        zoom: LocationUtils.getZoomLevel(locationRadius.toDouble())
    );

    _generateBoundaryCircle(currentUserProfileLocationCenter, locationRadius);
    markers.clear();
    markers.add(
      Marker(
        markerId: markerId,
        position: currentUserProfileLocationCenter,
      ),
    );
  }


  void _fillInUserProfileDetails(AuthenticatedUser user) {
    _firstNameController.text = user.userProfile?.firstName ?? "";
    _lastNameController.text = user.userProfile?.lastName ?? "";
    _emailController.text = user.user.email;
    _usernameController.text = user.user.username ?? "";
    _accountDetailsBloc.add(AccountDetailsChanged(
        user: user,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        photoUrl: user.userProfile?.photoUrl,
        gender: user.userProfile?.gender ?? 'Other'
    ));
  }

  // Hack to get around web elements under dialog getting tapped
  _setDialogShownToFalse() {
    Future.delayed(Duration(milliseconds: 250), () {
      setState(() {
        isDialogShown = false;
      });
    });
  }

  _deleteAccountButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        setState(() {
          isDialogShown = true;
        });
        showDialog(context: context, builder: (context) {
          Widget cancelButton = TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.teal),
            ),
            onPressed:  () {
              _setDialogShownToFalse();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          );
          Widget continueButton = TextButton(
            onPressed:  () {
              _setDialogShownToFalse();
              Navigator.pop(context);
              _performAccountDeletion();
            },
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
            ),
            child: const Text("Confirm"),
          );

          return AlertDialog(
            title: const Text("Delete Account Confirmation"),
            content: const Text("Are you sure you want to delete your account? This action is irreversible!"),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
      },
      child: const Text("Delete Account", style: TextStyle(fontSize: 15, color: Colors.white)),
    );
  }
  
  _performAccountDeletion() {
    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      _authenticationBloc.add(AccountDeletionRequested(user: authState.authenticatedUser));
    }
  }

  Widget _locationWidget() {
    final currentState = _authenticationBloc.state;
    if (currentState is AuthSuccessUserUpdateState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Discovery Radius', style: TextStyle(fontSize: 13),),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            height: 300,
            child: GoogleMap(
                onTap: (_) {
                  if (!isDialogShown) {
                    _goToDiscoveryRadiusView(currentState);
                  }
                },
                mapType: MapType.hybrid,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                markers: markers,
                circles: Set<Circle>.of(circles.values),
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                }
            ),
          )
        ],
      );
    }
    else {
      if (DeviceUtils.isAppRunningOnMobileBrowser()) {
        return WidgetUtils.progressIndicator();
      }
      else {
        return SkeletonLoader(
          builder: Container(
            margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            height: 300,
            child: GoogleMap(
                mapType: MapType.hybrid,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                markers: markers,
                circles: Set<Circle>.of(circles.values),
                initialCameraPosition: CameraPosition(
                    target: LocationUtils.defaultLocation,
                    tilt: 0,
                    zoom: LocationUtils.getZoomLevel(locationRadius.toDouble())
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                }
            ),
          ),
        );
      }
    }
  }

  _goToDiscoveryRadiusView(AuthSuccessUserUpdateState currentState) {
    Navigator.push<void>(
      context,
      DiscoveryRadiusView.route(
        currentUserProfileLocationCenter.latitude,
        currentUserProfileLocationCenter.longitude,
        locationRadius.toDouble(),
        currentState.authenticatedUser,
      ),
    );
  }

  Widget _spacer(double allPadding) => Padding(padding: EdgeInsets.all(allPadding));

  Widget _fullLengthRowElement(Widget child) {
    return Row(
      children: [
        const Padding(padding: EdgeInsets.all(12)),
        Expanded(child: child),
        const Padding(padding: EdgeInsets.all(12)),
      ],
    );
  }

  _saveAccountDetailsButton(AccountDetailsState state) {
    return PointerInterceptor(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          if (state is AccountDetailsModified) {
            SnackbarUtils.showSnackBarMedium(context, "Saving changes... please wait.");
            final authState = _authenticationBloc.state;
            if (authState is AuthSuccessUserUpdateState) {
              _accountDetailsBloc.add(AccountDetailsSaved(
                user: authState.authenticatedUser,
                firstName: state.firstName.value,
                lastName: state.lastName.value,
                photoUrl: state.photoUrl,
                selectedImage: state.selectedImage,
                selectedImageName: state.selectedImageName,
                gender: state.gender,
              ));
            }
          }
        },
        child: const Text("Save", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  _deleteImageCrossButton(AccountDetailsState state) {
    return GestureDetector(
      onTap: () {
        if (state is AccountDetailsModified) {
          _accountDetailsBloc.add(AccountDetailsChanged(
            user: state.user,
            firstName: state.firstName.value,
            lastName: state.lastName.value,
            gender: state.gender,
          ));
        }
      },
      child: Align(
        alignment: const Alignment(1 / 2, 0),
        child: Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.teal),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  _emailWidget() {
    return TextField(
        controller: _emailController,
        style: const TextStyle(color: Colors.grey),
        readOnly: true,
        key: const Key('accountDetailsForm_email_textField'),
        decoration: const InputDecoration(labelText: "Email", errorText: null));
  }

  _usernameField() {
    return TextField(
        controller: _usernameController,
        style: const TextStyle(color: Colors.grey),
        readOnly: true,
        key: const Key('accountDetailsForm_username_textField'),
        decoration: const InputDecoration(labelText: "Username", errorText: null));
  }

  _userPremiumStatus(AccountDetailsState state) {
    final currentState = state;
    if (currentState is AccountDetailsModified) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
        child: _premiumStatusIconButton(currentState),
      );
    } else {
      if (DeviceUtils.isAppRunningOnMobileBrowser()) {
        return WidgetUtils.progressIndicator();
      }
      else {
        return SkeletonLoader(
          highlightColor: Colors.teal,
          builder: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              onPressed: () async {},
              child: const AutoSizeText(
                  "Manage Fitcentive+",
                  maxLines: 1,
                  maxFontSize: 15,
                  style: TextStyle(fontSize: 15, color: Colors.white)
              ),
            ),
          ),
        );
      }
    }
  }

  _premiumStatusIconButton(AccountDetailsModified currentState) {
    if (currentState.user.user.isPremiumEnabled) {
      return ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          _goToManagePremiumRoute();
        },
        child: const AutoSizeText(
            "Manage Fitcentive+",
            maxLines: 1,
            maxFontSize: 15,
            style: TextStyle(fontSize: 15, color: Colors.white)
        ),
      );
    }
    else {
      return ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
        ),
        onPressed: () async {
          _goToUpgradeToPremiumRoute();
        },
        child: const AutoSizeText(
            "Activate Fitcentive+",
            maxLines: 1,
            maxFontSize: 15,
            style: TextStyle(fontSize: 15, color: Colors.white)
        ),
      );
    }
  }

  _goToManagePremiumRoute() {
    Navigator.push<bool>(
        context,
        ManagePremiumView.route(
          currentUserProfile: widget.currentUserProfile,
          authenticatedUser: widget.authenticatedUser,
        )
    ).then((isPremiumDisabled) {
      if (isPremiumDisabled ?? false) {
        _accountDetailsBloc.add(DisablePremiumAccountStatusForUser(user: widget.authenticatedUser));
      }
    });
  }

  _goToUpgradeToPremiumRoute() {
    Navigator.push<bool>(
        context,
        UpgradeToPremiumView.route(
            currentUserProfile: widget.currentUserProfile,
            authenticatedUser: widget.authenticatedUser,
        )
    ).then((isUpgradeComplete) {
      if (isUpgradeComplete ?? false) {
        _accountDetailsBloc.add(EnablePremiumAccountStatusForUser(user: widget.authenticatedUser));
      }
    });
  }

  _genderField(AccountDetailsState state) {
    if (state is AccountDetailsModified) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender', style: TextStyle(fontSize: 13),),
          DropdownButton<String>(
              isExpanded: true,
              value: selectedUserGender,
              items: ConstantUtils.genderTypes.map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              )).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                      user: state.user,
                      firstName: state.firstName.value,
                      lastName:state.lastName.value,
                      photoUrl: state.photoUrl,
                      gender: newValue
                  ));
                  setState(() {
                    selectedUserGender = newValue;
                  });
                }
              }
          )
        ],
      );
    } else {
      if (DeviceUtils.isAppRunningOnMobileBrowser()) {
        return WidgetUtils.progressIndicator();
      }
      else {
        return SkeletonLoader(
          builder: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gender', style: TextStyle(fontSize: 13),),
              DropdownButton<String>(
                  isExpanded: true,
                  value: 'Other',
                  items: ConstantUtils.genderTypes.map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  )).toList(),
                  onChanged: (newValue) {}
              )
            ],
          ),
        );
      }
    }
  }

  _nameField(String key, AccountDetailsState state) {
    return TextField(
        inputFormatters: [
          UpperCaseTextFormatter(),
        ],
        controller: key == "First Name" ? _firstNameController : _lastNameController,
        key: Key('accountDetailsForm_${key}_textField'),
        onChanged: (name) {
          if (state is AccountDetailsModified) {
            context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                user: state.user,
                firstName: key == "First Name" ? name : state.firstName.value,
                lastName: key == "Last Name" ? name : state.lastName.value,
                photoUrl: state.photoUrl,
                gender: state.gender,
            ));
          }
        },
        decoration: _getDecoration(state, key));
  }

  InputDecoration? _getDecoration(AccountDetailsState state, String key) {
    if (state is AccountDetailsModified) {
      return InputDecoration(
          labelText: key,
          errorText: key == "First Name"
              ? (state.firstName.invalid ? 'Invalid name' : null)
              : (state.lastName.invalid ? 'Invalid name' : null));
    } else {
      return InputDecoration(labelText: key, errorText: null);
    }
  }

  Widget _headerElement(AccountDetailsState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _userProfileImageView(state),
                _deleteImageCrossButton(state),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: _userPremiumStatus(state),
          ),
        )
      ],
    );
  }

  Widget _userProfileImageView(AccountDetailsState state) {
    String? photoUrlOpt;
    if (state is AccountDetailsModified) {
      photoUrlOpt = state.photoUrl;
    }
    return SizedBox(
      width: 100,
      height: 100,
      child: GestureDetector(
        onTap: () async {
          final Tuple2<Uint8List?, String?> imageAndName = await _picker.pickImage(context);
          if (state is AccountDetailsModified) {
            context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                user: state.user,
                firstName: state.firstName.value,
                lastName: state.lastName.value,
                photoUrl: state.photoUrl,
                selectedImage: imageAndName.item1,
                selectedImageName: imageAndName.item2,
                gender: state.gender,
            ));
          }
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: _getDecorationImage(state, photoUrlOpt),
          ),
          child: (photoUrlOpt == null && (state is AccountDetailsModified && state.selectedImage == null))
              ? const Icon(
            Icons.account_circle_outlined,
            color: Colors.teal,
            size: 100,
          )
              : null,
        ),
      ),
    );
  }

  _getDecorationImage(AccountDetailsState state, String? photoUrlOpt) {
    if (state is AccountDetailsModified && state.selectedImage != null) {
      return DecorationImage(
          image: MemoryImage(state.selectedImage!),
          fit: BoxFit.fitHeight
      );
    }
    else  if (photoUrlOpt != null) {
      return ImageUtils.getImage(widget.currentUserProfile.photoUrl, 500, 500);
    }
  }
}
