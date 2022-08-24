import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectUsernameView extends StatefulWidget {
  const SelectUsernameView({Key? key}) : super(key: key);

  @override
  State createState() {
    return SelectUsernameViewState();
  }
}

class SelectUsernameViewState extends State<SelectUsernameView> {

  Timer? _debounce;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Align(
          alignment: const Alignment(0, -1 / 3),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Enter your preferred username",
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  const Padding(padding: EdgeInsets.all(12)),
                  _usernameInput(),
                  const Padding(padding: EdgeInsets.all(12)),
                ],
              )),
        ),
      ),
    );
  }

  _usernameInput() {
    return BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
      builder: (context, state) {
        return TextField(
            focusNode: focusNode,
            key: const Key('completeProfileForm_usernameInput_textField'),
            onChanged: (username) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                final currentState = context.read<CompleteProfileBloc>().state;
                if (currentState is UsernameModified) {
                  context.read<CompleteProfileBloc>().add(UsernameChanged(user: currentState.user, username: username));
                }
              });
            },
            decoration: _getDecoration(state));
      },
    );
  }

  InputDecoration _getDecoration(CompleteProfileState state) {
    if (state is UsernameModified) {
      return InputDecoration(
        suffixIcon: _getSuffixIcon(state),
        labelText: 'username',
        errorText: state.username.invalid ? 'invalid username' : null,
      );
    } else {
      return InputDecoration(
        suffixIcon: _getSuffixIcon(state),
        labelText: 'username',
        errorText: null,
      );
    }
  }

  _getSuffixIcon(CompleteProfileState state) {
    if (state is UsernameModified) {
      if (state.doesUsernameExistAlready) {
        return const Icon(Icons.close, color: Colors.redAccent);
      }
      else {
        return const Icon(Icons.check, color: Colors.teal);
      }
    }

  }


}