import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_app/src/views/complete_profile/views/profile_info_view.dart';
import 'package:flutter_app/src/views/complete_profile/views/terms_and_conditions_view.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const CompleteProfilePage());
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

  static const MaterialColor BUTTON_AVAILABLE = Colors.teal;
  static const MaterialColor BUTTON_DISABLED = Colors.grey;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _completeProfileBloc = BlocProvider.of<CompleteProfileBloc>(context);
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);

    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessState) {
      _completeProfileBloc.add(InitialEvent(user: authState.authenticatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Complete profile')),
          body: _pageViews(),
          floatingActionButton: _nextButton(),
        ));
  }

  _nextButton() {
    return BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          return FloatingActionButton(
              onPressed: _onFloatingActionButtonPress,
              backgroundColor: _getBackgroundColor(),
              child: const Icon(Icons.navigate_next_sharp));
        });
  }

  MaterialColor _getBackgroundColor() {
    final currentState = _completeProfileBloc.state;
    if (currentState is CompleteProfileTermsAndConditionsModified && currentState.isValidState()) {
      return BUTTON_AVAILABLE;
    } else if (currentState is ProfileInfoModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is UsernameModified && currentState.status.isValid) {
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
          dateOfBirth: DateTime.parse(currentState.dateOfBirth.value)));
    } else if (currentState is UsernameModified && currentState.status.isValid) {
      _completeProfileBloc.add(UsernameSubmitted(user: currentState.user, username: currentState.username.value));
    }
    return null;
  }

  Widget _pageViews() {
    return BlocListener<CompleteProfileBloc, CompleteProfileState>(
      listener: (context, state) {
        if (state is CompleteProfileTermsAndConditionsModified) {
          _pageController.animateToPage(TERMS_AND_CONDITIONS_PAGE,
              duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is ProfileInfoModified) {
          _pageController.animateToPage(PROFILE_INFO_PAGE,
              duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is UsernameModified) {
          _pageController.animateToPage(USERNAME_PAGE,
              duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is ProfileInfoComplete) {
          // todo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile info is complete, must navigate to next section now!')),
          );
          Navigator.pop(context);
        }
      },
      child: BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
          buildWhen: (previous, current) => previous != current,
          builder: (context, state) {
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                CompleteProfileTermsAndConditionsView(),
                ProfileInfoView(),
                Text("Yet to come still"),
              ],
            );
          }),
    );
  }
}
