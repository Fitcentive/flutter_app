import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/utils/location_utils.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_app/src/views/complete_profile/views/profile_info_view.dart';
import 'package:flutter_app/src/views/shared_components/provide_location_view.dart';
import 'package:flutter_app/src/views/complete_profile/views/select_username_view.dart';
import 'package:flutter_app/src/views/complete_profile/views/terms_and_conditions_view.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CompleteProfilePage extends StatefulWidget {
  static const String routeName = "complete-profile";

  const CompleteProfilePage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider<CompleteProfileBloc>(
                    create: (context) => CompleteProfileBloc(
                          userRepository: RepositoryProvider.of<UserRepository>(context),
                          secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                          authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
                        )),
              ],
              child: const CompleteProfilePage(),
            ));
  }

  @override
  State createState() {
    return CompleteProfilePageState();
  }
}

class CompleteProfilePageState extends State<CompleteProfilePage> {
  late CompleteProfileBloc _completeProfileBloc;
  late AuthenticationBloc _authenticationBloc;
  final PageController _pageController = PageController();

  static const int TERMS_AND_CONDITIONS_PAGE = 0;
  static const int PROFILE_INFO_PAGE = 1;
  static const int USERNAME_PAGE = 2;
  static const int LOCATION_INFO_PAGE = 3;

  static const MaterialColor BUTTON_AVAILABLE = Colors.teal;
  static const MaterialColor BUTTON_DISABLED = Colors.grey;

  int currentPage = TERMS_AND_CONDITIONS_PAGE;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _completeProfileBloc = BlocProvider.of<CompleteProfileBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessState) {
      _completeProfileBloc.add(InitialEvent(user: authState.authenticatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_){
          if(_pageController.hasClients) {
            _pageController.animateToPage(currentPage, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
          }
    });
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Complete profile', style: TextStyle(color: Colors.teal),)),
          body: _pageViews(),
          floatingActionButton: _nextButton(),
        ));
  }

  _nextButton() {
    return BlocBuilder<CompleteProfileBloc, CompleteProfileState>(builder: (context, state) {
      return FloatingActionButton(
          onPressed: _onFloatingActionButtonPress,
          backgroundColor: _getBackgroundColor(),
          child: const Icon(Icons.navigate_next_sharp, color: Colors.white)
      );
    });
  }

  MaterialColor _getBackgroundColor() {
    final currentState = _completeProfileBloc.state;
    if (currentState is CompleteProfileTermsAndConditionsModified && currentState.isValidState()) {
      return BUTTON_AVAILABLE;
    } else if (currentState is ProfileInfoModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is UsernameModified &&
        currentState.status.isValid &&
        !currentState.doesUsernameExistAlready) {
      return BUTTON_AVAILABLE;
    } else if (currentState is LocationInfoModified) {
      return BUTTON_AVAILABLE;
    } else {
      return BUTTON_DISABLED;
    }
  }

  VoidCallback? _onFloatingActionButtonPress() {
    final currentState = _completeProfileBloc.state;
    if (currentState is CompleteProfileTermsAndConditionsModified && currentState.isValidState()) {
      _completeProfileBloc.add(CompleteProfileTermsAndConditionsSubmitted(
          user: currentState.user,
          termsAndConditions: currentState.termsAndConditions,
          marketingEmails: currentState.marketingEmails));
    } else if (currentState is ProfileInfoModified && currentState.status.isValid) {
      _completeProfileBloc.add(ProfileInfoSubmitted(
          user: currentState.user,
          firstName: currentState.firstName.value,
          lastName: currentState.lastName.value,
          dateOfBirth: DateTime.parse(currentState.dateOfBirth.value),
          gender: currentState.gender
      ));
    } else if (currentState is UsernameModified && currentState.status.isValid) {
      _completeProfileBloc.add(UsernameSubmitted(user: currentState.user, username: currentState.username.value));
    } else if (currentState is LocationInfoModified) {
      _completeProfileBloc.add(
          LocationInfoSubmitted(
              user: currentState.user,
              coordinates: currentState.selectedCoordinates,
              radius: currentState.radius
          )
      );
    }
    return null;
  }

  Widget _pageViews() {
    return BlocListener<CompleteProfileBloc, CompleteProfileState>(
      listener: (context, state) {
        setState(() {
          if (state is CompleteProfileTermsAndConditionsModified) {
            currentPage = TERMS_AND_CONDITIONS_PAGE;
          }
          if (state is ProfileInfoModified) {
            currentPage = PROFILE_INFO_PAGE;
          }
          if (state is UsernameModified) {
            currentPage = USERNAME_PAGE;
          }
          if (state is LocationInfoModified) {
            currentPage = LOCATION_INFO_PAGE;
          }
          if (state is ProfileInfoComplete) {
            Navigator.pushAndRemoveUntil<void>(context, HomePage.route(), (route) => false);
          }
        });

      },
      child: BlocBuilder<CompleteProfileBloc, CompleteProfileState>(builder: (context, state) {
        final pageView = PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const CompleteProfileTermsAndConditionsView(),
            const ProfileInfoView(),
            const SelectUsernameView(),
            ProvideLocationView(
                longitude: LocationUtils.defaultLocation.longitude,
                latitude: LocationUtils.defaultLocation.latitude,
                radius: LocationUtils.defaultRadius.toDouble(),
                updateBlocState: _updateBlocState,
            ),
          ],
        );
        if (state is InitialState) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
        else if (state is ProfileInfoComplete) {
          _completeProfileBloc.add(ForceUpdateAuthState(state.user));
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
        else {
          return pageView;
        }
      }),
    );
  }

  _updateBlocState(LatLng coordinates, int radius) {
    final currentState = _completeProfileBloc.state;
    if (currentState is LocationInfoModified) {
      _completeProfileBloc.add(
          LocationInfoChanged(
              user: currentState.user,
              coordinates: coordinates,
              radius: radius,
          )
      );
    }
  }
}
