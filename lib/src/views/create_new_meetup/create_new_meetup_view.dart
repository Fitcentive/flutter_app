import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_meetup_participants_view.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/select_meetup_details_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateNewMeetupView extends StatefulWidget {
  static const String routeName = "create-meetup";

  final PublicUserProfile currentUserProfile;

  const CreateNewMeetupView({Key? key, required this.currentUserProfile}): super(key: key);

  static Route route(PublicUserProfile currentUserProfile) => MaterialPageRoute<void>(
      settings: const RouteSettings(
          name: routeName
      ),
      builder: (_) =>  MultiBlocProvider(
        providers: [
          BlocProvider<CreateNewMeetupBloc>(
              create: (context) => CreateNewMeetupBloc(
                userRepository: RepositoryProvider.of<UserRepository>(context),
                meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
                secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
              )),
        ],
        child: CreateNewMeetupView(currentUserProfile: currentUserProfile),
      )
  );

  @override
  State createState() {
    return CreateNewMeetupViewState();
  }
}

class CreateNewMeetupViewState extends State<CreateNewMeetupView> {
  bool isPremiumEnabled = false;
  bool isRequestingMoreData = false;
  late final CreateNewMeetupBloc _createNewMeetupBloc;

  final PageController _pageController = PageController();

  Icon floatingActionButtonIcon = const Icon(Icons.navigate_next, color: Colors.white);
  Widget? dynamicActionButtons;

  bool isMeetupBeingSavedCurrently = false;

  List<PublicUserProfile> meetupParticipantsState = List.empty();

  @override
  void initState() {
    super.initState();

    _createNewMeetupBloc = BlocProvider.of<CreateNewMeetupBloc>(context);
    _createNewMeetupBloc.add(NewMeetupChanged(
      currentUserProfile: widget.currentUserProfile,
      meetupParticipantUserIds: List.empty(),
      currentUserAvailabilities: List.empty(),
    ));

    dynamicActionButtons = _singleFloatingActionButton();
    isPremiumEnabled = WidgetUtils.isPremiumEnabledForUser(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meetup', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: BlocListener<CreateNewMeetupBloc, CreateNewMeetupState>(
        listener: (context, state) {
          if (state is MeetupCreatedAndReadyToPop) {
            // Go back to previous screen
            SnackbarUtils.showSnackBar(context, "Meetup created successfully!");
            Navigator.pop(context);
          }
          else if (state is MeetupBeingCreated) {
            SnackbarUtils.showSnackBarShort(context, "Hang on while we save your meetup...");
            setState(() {
              isMeetupBeingSavedCurrently = true;
              dynamicActionButtons = _dynamicFloatingActionButtons();
            });
          }
        },
        child: _pageViews(isPremiumEnabled),
      ),
      floatingActionButton: dynamicActionButtons,
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
    );
  }

  _singleFloatingActionButton() {
    return FloatingActionButton(
        heroTag: "CreateNewMeetupViewbutton0",
        onPressed: _onActionButtonPress,
        backgroundColor: Colors.teal,
        child: floatingActionButtonIcon
    );
  }


  _dynamicFloatingActionButtons() {
    return Visibility(
      visible: !isMeetupBeingSavedCurrently,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(30, 0, 0, 0),
            child: FloatingActionButton(
                heroTag: "CreateNewMeetupViewbutton1",
                onPressed: _onBackFloatingActionButtonPress,
                backgroundColor: Colors.teal,
                child: const Icon(Icons.navigate_before, color: Colors.white)
            ),
          ),
          FloatingActionButton(
              heroTag: "CreateNewMeetupViewbutton2",
              onPressed: _onActionButtonPress,
              backgroundColor: Colors.teal,
              child: floatingActionButtonIcon
          )
        ],
      ),
    );
  }

  VoidCallback? _onBackFloatingActionButtonPress() {
    final currentState = _createNewMeetupBloc.state;
    if (currentState is MeetupModified) {
      final currentPage = _pageController.page;
      if (currentPage != null) {
        _goToPreviousPageOrNothing(currentPage.toInt(), currentState);
      }
    }
    return null;
  }

  VoidCallback? _onActionButtonPress() {
    final currentState = _createNewMeetupBloc.state;
    if (currentState is MeetupModified) {
      final currentPage = _pageController.page;
      if (currentPage != null) {
        if (_isPageDataValid(currentPage.toInt(), currentState)) {
          _savePageData(currentPage.toInt(), currentState);
          _moveToNextPageElseDoNothing(currentPage.toInt(), currentState);
        }
        else {
          if (currentPage == 0 || currentPage == 2) {
            SnackbarUtils.showSnackBar(context, "Please add at least one participant to the meetup!");
          }
          else {
            SnackbarUtils.showSnackBar(context, "Please complete the missing fields!");
          }
        }
      }
    }
    return null;
  }

  void _goToPreviousPageOrNothing(int currentPage, MeetupModified state) {
    if (currentPage != 0) {
      // Move to previous page if not at first page
      _pageController.animateToPage(currentPage - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut
      );
    }
  }

  void _moveToNextPageElseDoNothing(int currentPage, MeetupModified state) {
    if (currentPage < 2) {
      // Move to next page if not at last page
      _pageController.animateToPage(currentPage + 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn
      );
    }
  }

  void _savePageData(int pageNumber, MeetupModified state) {
    switch (pageNumber) {
      case 0:
        // Nothing to do here
        return;
      case 1:
      // Nothing to do here
        return;
      case 2:
        final currentState = _createNewMeetupBloc.state;
        if (currentState is MeetupModified) {
          _createNewMeetupBloc.add(
              SaveNewMeetup(
                  currentUserProfile: currentState.currentUserProfile,
                  meetupParticipantUserIds: currentState.participantUserProfiles.map((e) => e.userId).toList(),
                  currentUserAvailabilities: currentState.currentUserAvailabilities,
                  meetupTime: currentState.meetupTime,
                  meetupName: currentState.meetupName,
                  location: currentState.location,
              )
          );
        }
        return;
      default:
        return;
    }
  }

  bool _isPageDataValid(int pageNumber, MeetupModified state) {
    switch (pageNumber) {
      case 0:
        // Validate participantUserProfiles data
        return state.participantUserProfiles.isNotEmpty;
      case 1:
      // Validate rest of the meetup data
        return state.meetupName != null && state.participantUserProfiles.isNotEmpty;
      case 2:
        return state.participantUserProfiles.isNotEmpty;
      default:
        return false;
    }
  }

  _changeButtonIconIfNeeded(int pageNumber) {
    if (pageNumber == 2) {
      setState(() {
        floatingActionButtonIcon = const Icon(Icons.check, color: Colors.white);
      });
    }
    else {
      setState(() {
        floatingActionButtonIcon = const Icon(Icons.navigate_next, color: Colors.white);
      });
    }
  }

  _changeFloatingActionButtonsIfNeeded(int pageNumber) {
    if (pageNumber == 0) {
      setState(() {
        dynamicActionButtons =  _singleFloatingActionButton();
      });
    }
    else {
      setState(() {
        dynamicActionButtons = _dynamicFloatingActionButtons();
      });
    }
  }

  Widget _pageViews(bool isPremiumEnabled) {
    return BlocBuilder<CreateNewMeetupBloc, CreateNewMeetupState>(
        builder: (context, state) {
          if (state is MeetupModified) {
            return PageView(
              controller: _pageController,
              onPageChanged: (pageNumber) {
                _changeButtonIconIfNeeded(pageNumber);
                _changeFloatingActionButtonsIfNeeded(pageNumber);
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AddMeetupParticipantsView(
                  currentUserProfile: widget.currentUserProfile,
                  participantUserIds: state.participantUserProfiles.map((e) => e.userId).toList(),
                  maxOtherParticipantsLimit: isPremiumEnabled ? ConstantUtils.MAX_OTHER_MEETUP_PARTICIPANTS_PREMIUM : ConstantUtils.MAX_OTHER_MEETUP_PARTICIPANTS_FREE,
                ),
                SelectMeetupDetailsView(
                    currentUserProfile: widget.currentUserProfile,
                    participantUserIds: state.participantUserProfiles.map((e) => e.userId).toList()
                ),
                AddOwnerAvailabilitiesView(
                    currentUserProfile: widget.currentUserProfile,
                    participantUserIds: state.participantUserProfiles.map((e) => e.userId).toList()
                )
              ],
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

}