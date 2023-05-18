import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/user_fitness_profile_bloc.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/user_fitness_profile_event.dart';
import 'package:flutter_app/src/views/user_fitness_profile/bloc/user_fitness_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserFitnessProfileView extends StatefulWidget {
  static const String routeName = "user/fitness-profile/update";

  final PublicUserProfile currentUserProfile;
  final FitnessUserProfile? currentFitnessUserProfile;

  const UserFitnessProfileView({
    Key? key,
    required this.currentUserProfile,
    required this.currentFitnessUserProfile,
  }) : super(key: key);

  static Route<FitnessUserProfile> route(PublicUserProfile currentUserProfile, FitnessUserProfile? currentFitnessUserProfile) {
    return MaterialPageRoute<FitnessUserProfile>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<UserFitnessProfileBloc>(
                create: (context) => UserFitnessProfileBloc(
                  diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: UserFitnessProfileView(
              currentUserProfile: currentUserProfile,
              currentFitnessUserProfile: currentFitnessUserProfile
          ),
        )
    );
  }

  @override
  State createState() {
    return UserFitnessProfileViewState();
  }
}

class UserFitnessProfileViewState extends State<UserFitnessProfileView> {

  late UserFitnessProfileBloc _createUserFitnessProfileBloc;

  double? userInputWeight;
  double? userInputHeight;

  @override
  void initState() {
    super.initState();

    _createUserFitnessProfileBloc = BlocProvider.of<UserFitnessProfileBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Fitness Profile', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _renderBody(),
      floatingActionButton: FloatingActionButton(
          heroTag: "SaveCreateUserFitnessProfileButton",
          onPressed: _saveUserFitnessDetails,
          backgroundColor: Colors.teal,
          child: const Icon(Icons.save, color: Colors.white)
      ),
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
    );
  }

  _saveUserFitnessDetails() {
    // Validate first if all fields are present
    if (userInputHeight == null) {
      SnackbarUtils.showSnackBar(context, "Your height cannot be left blank!");
    }
    else if (userInputWeight == null) {
      SnackbarUtils.showSnackBar(context, "Your weight cannot be left blank!");
    }
    else {
      _createUserFitnessProfileBloc.add(
          UpsertUserFitnessProfile(
            userId: widget.currentUserProfile.userId,
            heightInCm: userInputHeight!,
            weightInLbs: userInputWeight!
          )
      );
    }
  }

  Widget _renderBody() {
    return BlocListener<UserFitnessProfileBloc, UserFitnessProfileState>(
      listener: (context, state) {
        if (state is UserFitnessProfileUpserted) {
          SnackbarUtils.showSnackBar(context, "Fitness profile updated successfully!");
          Navigator.pop(context, state.fitnessUserProfile);
        }
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(5),
            _renderText(),
            WidgetUtils.spacer(10),
            _renderUserImage(),
            WidgetUtils.spacer(10),
            _renderUserName(),
            WidgetUtils.spacer(10),
            _renderUserWeight(),
            WidgetUtils.spacer(10),
            _renderUserHeight(),
          ]),
        ),
      )
    );
  }

  _renderUserWeight() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Weight (in lbs)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )
          ),
          Expanded(
              flex: 7,
              child: TextFormField(
                initialValue: widget.currentFitnessUserProfile?.weightInLbs.toStringAsFixed(2),
                onChanged: (text) {
                  final w = double.parse(text);
                  setState(() {
                    userInputWeight = w;
                  });
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "150",
                  hintStyle: TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
          ),
          WidgetUtils.spacer(2.5),
          const Expanded(
              flex: 2,
              child: Text(
                "lbs",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              )
          )
        ],
      ),
    );
  }

  _renderUserHeight() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Height (in cms)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )
          ),
          Expanded(
              flex: 7,
              child: TextFormField(
                initialValue: widget.currentFitnessUserProfile?.heightInCm.toStringAsFixed(2),
                onChanged: (text) {
                  final h = double.parse(text);
                  setState(() {
                    userInputHeight = h;
                  });
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "150",
                  hintStyle: TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
          ),
          WidgetUtils.spacer(2.5),
          const Expanded(
              flex: 2,
              child: Text(
                "cms",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              )
          )
        ],
      ),
    );
  }

  _renderText() {
    if (widget.currentFitnessUserProfile == null) {
      return const Center(
        child: Text(
          "Please tell us a little more about yourself",
          style: TextStyle(
            color: Colors.teal,
            fontSize: 16,
          ),
        ),
      );
    }
  }

  _renderUserName() {
    return Center(
      child: Text(
        "${widget.currentUserProfile.firstName} ${widget.currentUserProfile.lastName}",
        style: const TextStyle(
          color: Colors.teal,
          fontWeight: FontWeight.bold,
          fontSize: 20
        ),
      ),
    );
  }

  _renderUserImage() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: _getDecorationImage(),
        ),
        child: (widget.currentUserProfile.photoUrl == null)
            ? const Icon(
              Icons.account_circle_outlined,
              color: Colors.teal,
              size: 100,
            )
            : null,
      ),
    );
  }


  _getDecorationImage() {
    if (widget.currentUserProfile.photoUrl != null) {
      return DecorationImage(
          image: NetworkImage("${ImageUtils.imageBaseUrl}/${widget.currentUserProfile.photoUrl}?transform=500x500"), fit: BoxFit.fitHeight);
    }
  }
}