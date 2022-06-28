import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_bloc.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_event.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountDetailsView extends StatefulWidget {
  const AccountDetailsView({Key? key});

  static Widget withBloc() => MultiBlocProvider(
        providers: [
          BlocProvider<AccountDetailsBloc>(
              create: (context) => AccountDetailsBloc(
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                  )),
        ],
        child: const AccountDetailsView(),
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

  late AuthenticationBloc _authenticationBloc;
  late AccountDetailsBloc _accountDetailsBloc;

  @override
  void initState() {
    super.initState();
    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    _accountDetailsBloc = BlocProvider.of<AccountDetailsBloc>(context);

    final authState = _authenticationBloc.state;
    if (authState is AuthSuccessUserUpdateState) {
      _fillInUserProfileDetails(authState.authenticatedUser);
    } else if (authState is AuthSuccessState) {
      _fillInUserProfileDetails(authState.authenticatedUser);
    }
  }

  void _fillInUserProfileDetails(AuthenticatedUser user) {
    _firstNameController.text = user.userProfile?.firstName ?? "";
    _lastNameController.text = user.userProfile?.lastName ?? "";
    _emailController.text = user.user.email;
    _usernameController.text = user.user.username ?? "";
    _accountDetailsBloc
        .add(AccountDetailsChanged(firstName: _firstNameController.text, lastName: _lastNameController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountDetailsBloc, AccountDetailsState>(builder: (context, state) {
      return Scaffold(
        floatingActionButton: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
          ),
          onPressed: () async {
            if (state is AccountDetailsModified) {
              _accountDetailsBloc.add(AccountDetailsSaved(
                firstName: state.firstName.value,
                lastName: state.lastName.value,
                photoUrl: state.photoUrl,
              ));
            }
          },
          child: const Text("Save", style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(padding: EdgeInsets.all(12)),
              SizedBox(width: 100, height: 100, child: _circleImageView()),
              GestureDetector(
                onTap: () {
                  print("Yet to implement");
                },
                child: Align(
                  alignment: const Alignment(1 / 5, 0),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.all(12)),
              Row(
                children: [
                  const Padding(padding: EdgeInsets.all(12)),
                  Expanded(child: _firstNameWidget("First Name")),
                  const Padding(padding: EdgeInsets.all(12)),
                ],
              ),
              const Padding(padding: EdgeInsets.all(6)),
              Row(
                children: [
                  const Padding(padding: EdgeInsets.all(12)),
                  Expanded(child: _firstNameWidget("Last Name")),
                  const Padding(padding: EdgeInsets.all(12)),
                ],
              ),
              const Padding(padding: EdgeInsets.all(6)),
              Row(
                children: [
                  const Padding(padding: EdgeInsets.all(12)),
                  Expanded(child: _emailWidget()),
                  const Padding(padding: EdgeInsets.all(12)),
                ],
              ),
              const Padding(padding: EdgeInsets.all(6)),
              Row(
                children: [
                  const Padding(padding: EdgeInsets.all(12)),
                  Expanded(child: _usernameWidget()),
                  const Padding(padding: EdgeInsets.all(12)),
                ],
              ),
              const Padding(padding: EdgeInsets.all(6))
            ],
          ),
        ),
      );
    });
  }

  _emailWidget() {
    return TextField(
        controller: _emailController,
        style: const TextStyle(color: Colors.grey),
        readOnly: true,
        key: const Key('accountDetailsForm_email_textField'),
        decoration: const InputDecoration(labelText: "Email", errorText: null));
  }

  _usernameWidget() {
    return TextField(
        controller: _usernameController,
        style: const TextStyle(color: Colors.grey),
        readOnly: true,
        key: const Key('accountDetailsForm_username_textField'),
        decoration: const InputDecoration(labelText: "Username", errorText: null));
  }

  _firstNameWidget(String key) {
    return BlocBuilder<AccountDetailsBloc, AccountDetailsState>(
      builder: (context, state) {
        return TextField(
            controller: key == "First Name" ? _firstNameController : _lastNameController,
            key: Key('accountDetailsForm_${key}_textField'),
            onChanged: (name) {
              if (state is AccountDetailsModified) {
                print("Updating bloc ");
                context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                    firstName: key == "First Name" ? name : state.firstName.value,
                    lastName: key == "Last Name" ? name : state.lastName.value,
                    photoUrl: state.photoUrl));
              }
            },
            decoration: _getDecoration(state, key));
      },
    );
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
    return null;
  }

  Widget _circleImageView() {
    return GestureDetector(
      onTap: () async {
        print("No implementation for onTap yet");
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: _getDecorationImage(),
        ),
      ),
    );
  }

  _getDecorationImage() {
    final authCurrentState = _authenticationBloc.state;
    if (authCurrentState is AuthSuccessState) {
      final photoUrlOpt = authCurrentState.authenticatedUser.userProfile?.photoUrl;
      if (photoUrlOpt != null) {
        return DecorationImage(
            image: NetworkImage("${ImageUtils.imageBaseUrl}/100x100/$photoUrlOpt"), fit: BoxFit.fitHeight);
      }
    } else if (authCurrentState is AuthSuccessUserUpdateState) {
      final photoUrlOpt = authCurrentState.authenticatedUser.userProfile?.photoUrl;
      if (photoUrlOpt != null) {
        return DecorationImage(
            image: NetworkImage("${ImageUtils.imageBaseUrl}/100x100/$photoUrlOpt"), fit: BoxFit.fitHeight);
      }
    } else {
      return null;
    }
  }
}
