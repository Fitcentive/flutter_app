import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ProfileInfoView extends StatefulWidget {

  const ProfileInfoView({Key? key}) : super(key: key);

  @override
  State createState() {
    return ProfileInfoViewState();
  }

}

class ProfileInfoViewState extends State<ProfileInfoView> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  late final CompleteProfileBloc _completeProfileBloc;


  @override
  void initState() {
    _completeProfileBloc = BlocProvider.of<CompleteProfileBloc>(context);
    final currentState = _completeProfileBloc.state;
    if (currentState is ProfileInfoModified) {
      _firstNameController.text = currentState.user.userProfile?.firstName ?? "";
      _lastNameController.text = currentState.user.userProfile?.lastName ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Tell us a little more about yourself",
                      style: appTheme.textTheme.headline6,
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    _nameInput("First Name"),
                    const Padding(padding: EdgeInsets.all(6)),
                    _nameInput("Last Name"),
                    const Padding(padding: EdgeInsets.all(6)),
                    // todo - make this a dialog popup
                    _datePicker(),
                  ],
                );
              })),
    );
  }

  Widget _datePicker() {
    return BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
      builder: (context, state) {
        return SfDateRangePicker(
          onSelectionChanged: (selection) {
            if (state is ProfileInfoModified) {
              context.read<CompleteProfileBloc>().add(ProfileInfoChanged(
                  user: state.user,
                  firstName: state.firstName.value,
                  lastName: state.lastName.value,
                  dateOfBirth: selection.value
              ));
            }
          },
          selectionMode: DateRangePickerSelectionMode.single,
          initialSelectedDate: DateTime.now(),
        );
      },
    );
  }

  Widget _nameInput(String key) {
    return BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
            controller: key == "First Name" ? _firstNameController : _lastNameController,
            key: Key('completeProfileForm_${key}_textField'),
            onChanged: (name) {
              if (state is ProfileInfoModified) {
                context.read<CompleteProfileBloc>().add(ProfileInfoChanged(
                    user: state.user,
                    firstName: key == "First Name" ? name : state.firstName.value,
                    lastName: key == "Last Name" ? name : state.lastName.value,
                    dateOfBirth: DateTime.parse(state.dateOfBirth.value)));
              }
            },
            decoration: _getDecoration(state, key));
      },
    );
  }

  InputDecoration _getDecoration(CompleteProfileState state, String key) {
    if (state is ProfileInfoModified) {
      return InputDecoration(
          labelText: key,
          errorText: key == "First Name"
              ? (state.firstName.invalid ? 'Invalid name' : null)
              : (state.lastName.invalid ? 'Invalid name' : null));
    } else {
      return InputDecoration(
        labelText: key,
        errorText: null,
      );
    }
  }
}
