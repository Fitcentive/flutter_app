import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/string_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  String selectedUserGender = ConstantUtils.defaultGender;

  @override
  void initState() {
    super.initState();

    _completeProfileBloc = BlocProvider.of<CompleteProfileBloc>(context);
    final currentState = _completeProfileBloc.state;
    if (currentState is ProfileInfoModified) {
      final userFirstName = currentState.user.userProfile?.firstName ?? "";
      final userLastName = currentState.user.userProfile?.lastName ?? "";
      _firstNameController.text = userFirstName;
      _lastNameController.text = userLastName;
      _completeProfileBloc.add(ProfileInfoChanged(
          user: currentState.user,
          firstName: userFirstName,
          lastName: userLastName,
          dateOfBirth: DateTime.parse(currentState.dateOfBirth.value),
          gender: currentState.user.userProfile?.gender ?? ConstantUtils.defaultGender
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Align(
          alignment: const Alignment(0, -1 / 3),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Tell us a little more about yourself",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        const Padding(padding: EdgeInsets.all(20)),
                        _nameInput("First Name"),
                        const Padding(padding: EdgeInsets.all(6)),
                        _nameInput("Last Name"),
                        const Padding(padding: EdgeInsets.all(20)),
                        Text("Gender", style: Theme.of(context).textTheme.headline6,),
                        _genderPicker(),
                        WidgetUtils.spacer(15),
                        Text("Date of birth", style: Theme.of(context).textTheme.headline6,),
                        const Padding(padding: EdgeInsets.all(6)),
                        _datePickerButton(),
                        WidgetUtils.spacer(5),
                        _renderDateOfBirthHint(),
                      ],
                    );
                  })),
        ),
      ),
    );
  }

  _renderDateOfBirthHint() {
    return const Center(
      child: Text(
        "You must be born on or after 2010-01-01",
        style: TextStyle(
          fontSize: 12,
          color: Colors.teal
        ),
      ),
    );
  }

  Widget _genderPicker() {
    return  Container(
      margin: const EdgeInsets.fromLTRB(0, 7.5, 0, 0),
      child: DropdownButton<String>(
          value: selectedUserGender,
          items: ConstantUtils.genderTypes.map((e) => DropdownMenuItem<String>(
            value: e,
            child: Text(e),
          )).toList(),
          onChanged: (newValue) {
            final currentState = context.read<CompleteProfileBloc>().state;
            if (currentState is ProfileInfoModified) {
              if (newValue != null) {
                _completeProfileBloc.add(ProfileInfoChanged(
                    user: currentState.user,
                    firstName: _firstNameController.value.text,
                    lastName: _lastNameController.value.text,
                    dateOfBirth: DateTime.parse(currentState.dateOfBirth.value),
                    gender: newValue
                ));
                setState(() {
                  selectedUserGender = newValue;
                });
              }
            }
          }
      ),
    );
  }

  Widget _datePickerButton() {
    final currentState = context.read<CompleteProfileBloc>().state;
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        if (currentState is ProfileInfoModified) {
          final selectedDate = await showDatePicker(
            builder: (BuildContext context, Widget? child) {
              return Theme(
                  data: ThemeData(primarySwatch: Colors.teal),
                  child: child!
              );
            },
            context: context,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDate: DateTime.parse(currentState.dateOfBirth.value),
            firstDate: DateTime(ConstantUtils.EARLIEST_YEAR),
            lastDate: DateTime(ConstantUtils.LATEST_YEAR),
          );
          _completeProfileBloc.add(ProfileInfoChanged(
              user: currentState.user,
              firstName: _firstNameController.value.text,
              lastName: _lastNameController.value.text,
              dateOfBirth: selectedDate ?? DateTime.parse(currentState.dateOfBirth.value),
              gender: currentState.gender,
          ));
        }
      },
      child: Text(
          (currentState is ProfileInfoModified) ? currentState.dateOfBirth.value : "Bad State",
          style: const TextStyle(
              fontSize: 15,
              color: Colors.white
          )),
    );
  }

  Widget _nameInput(String key) {
    return BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
      builder: (context, state) {
        return TextField(
            inputFormatters: [
              UpperCaseTextFormatter(),
            ],
            controller: key == "First Name" ? _firstNameController : _lastNameController,
            key: Key('completeProfileForm_${key}_textField'),
            onChanged: (name) {
              if (state is ProfileInfoModified) {
                context.read<CompleteProfileBloc>().add(ProfileInfoChanged(
                    user: state.user,
                    firstName: key == "First Name" ? name : state.firstName.value,
                    lastName: key == "Last Name" ? name : state.lastName.value,
                    dateOfBirth: DateTime.parse(state.dateOfBirth.value),
                    gender: state.gender
                ));
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
