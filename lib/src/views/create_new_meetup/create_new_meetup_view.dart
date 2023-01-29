import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_bloc.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_meetup_participants_view.dart';
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
  bool isRequestingMoreData = false;
  late final CreateNewMeetupBloc _createNewMeetupBloc;

  final PageController _pageController = PageController();

  Icon floatingActionButtonIcon = const Icon(Icons.navigate_next, color: Colors.white);
  Widget? dynamicActionButtons;

  List<PublicUserProfile> meetupParticipantsState = List.empty();

  @override
  void initState() {
    super.initState();

    _createNewMeetupBloc = BlocProvider.of<CreateNewMeetupBloc>(context);
    _createNewMeetupBloc.add(NewMeetupChanged(
      meetupParticipantUserIds: List.empty(),
      currentUserAvailabilities: List.empty(),
    ));

    dynamicActionButtons = _singleFloatingActionButton();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meetup', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _pageViews(),
      floatingActionButton: dynamicActionButtons,
    );
  }

  _singleFloatingActionButton() {
    return FloatingActionButton(
        onPressed: _onActionButtonPress,
        backgroundColor: Colors.teal,
        child: floatingActionButtonIcon
    );
  }


  _dynamicFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(30, 0, 0, 0),
          child: FloatingActionButton(
              heroTag: "button1",
              onPressed: _onBackFloatingActionButtonPress,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.navigate_before, color: Colors.white)
          ),
        ),
        FloatingActionButton(
            heroTag: "button2",
            onPressed: _onActionButtonPress,
            backgroundColor: Colors.teal,
            child: floatingActionButtonIcon
        )
      ],
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
          _moveToNextPageOrPop(currentPage.toInt(), currentState);
        }
        else {
          SnackbarUtils.showSnackBar(context, "Please complete the missing fields!");
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

  void _moveToNextPageOrPop(int currentPage, MeetupModified state) {
    if (currentPage < 1) {
      // Move to next page if not at last page
      _pageController.animateToPage(currentPage + 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn
      );
    }
    else {
      // Go back to previous screen
      SnackbarUtils.showSnackBar(context, "Meetup created successfully!");
      Navigator.pop(context);
    }
  }

  void _savePageData(int pageNumber, MeetupModified state) {
    switch (pageNumber) {
      case 0:

        return;
      case 1:

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
        return state.meetupName != null;
      default:
        return false;
    }
  }

  _changeButtonIconIfNeeded(int pageNumber) {
    if (pageNumber == 8) {
      setState(() {
        floatingActionButtonIcon = const Icon(Icons.save, color: Colors.white);
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

  Widget _pageViews() {
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
                ),
                Center(
                  child: Text("KAHOOTED"),
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