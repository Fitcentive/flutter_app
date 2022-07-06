import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/repos/rest/image_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_bloc.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_event.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_state.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class AccountDetailsView extends StatefulWidget {
  const AccountDetailsView({Key? key});

  static Widget withBloc() => MultiBlocProvider(
        providers: [
          BlocProvider<AccountDetailsBloc>(
              create: (context) => AccountDetailsBloc(
                    userRepository: RepositoryProvider.of<UserRepository>(context),
                    imageRepository: RepositoryProvider.of<ImageRepository>(context),
                    secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                    authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
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

  final ImagePicker _picker = ImagePicker();

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
    }
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
        photoUrl: user.userProfile?.photoUrl));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthSuccessUserUpdateState) {
          _fillInUserProfileDetails(state.authenticatedUser);
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
                photoUrl: state.photoUrl));
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
                  _userProfileImageView(state),
                  _deleteImageCrossButton(state),
                  _spacer(12),
                  _fullLengthRowElement(_nameField("First Name", state)),
                  _spacer(6),
                  _fullLengthRowElement(_nameField("Last Name", state)),
                  _spacer(6),
                  _fullLengthRowElement( _emailWidget()),
                  _spacer(6),
                  _fullLengthRowElement(_usernameField()),
                  _spacer(6),
                ],
              ),
            ),
          );
        }),
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
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        if (state is AccountDetailsModified) {
          _accountDetailsBloc.add(AccountDetailsSaved(
            user: state.user,
            firstName: state.firstName.value,
            lastName: state.lastName.value,
            photoUrl: state.photoUrl,
            selectedImage: state.selectedImage,
          ));
        }
      },
      child: const Text("Save", style: TextStyle(fontSize: 15, color: Colors.white)),
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
          ));
        }
      },
      child: Align(
        alignment: const Alignment(1 / 5, 0),
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

  _nameField(String key, AccountDetailsState state) {
    return TextField(
        controller: key == "First Name" ? _firstNameController : _lastNameController,
        key: Key('accountDetailsForm_${key}_textField'),
        onChanged: (name) {
          if (state is AccountDetailsModified) {
            context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                user: state.user,
                firstName: key == "First Name" ? name : state.firstName.value,
                lastName: key == "Last Name" ? name : state.lastName.value,
                photoUrl: state.photoUrl));
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
          final imageSource = await showDialog(context: context, builder: (context) {
            return SimpleDialog(
              title: const Text("Select image source"),
              children: [
                SimpleDialogOption(
                  child: const Text("Gallery"),
                  onPressed: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                SimpleDialogOption(
                  child: const Text("Camera"),
                  onPressed: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            );
          });
          final XFile? image = await _picker.pickImage(source: imageSource);
          if (state is AccountDetailsModified) {
            context.read<AccountDetailsBloc>().add(AccountDetailsChanged(
                user: state.user,
                firstName: state.firstName.value,
                lastName: state.lastName.value,
                photoUrl: state.photoUrl,
                selectedImage: image
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
        image: FileImage(File(state.selectedImage!.path)),
          fit: BoxFit.fitHeight
      );
    }
    else  if (photoUrlOpt != null) {
      return DecorationImage(
          image: NetworkImage("${ImageUtils.imageBaseUrl}/$photoUrlOpt?transform=100x100"), fit: BoxFit.fitHeight);
    }
  }
}