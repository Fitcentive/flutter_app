import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
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

  static Route<FitnessUserProfile> route(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile? currentFitnessUserProfile
) {
    return MaterialPageRoute<FitnessUserProfile>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<UserFitnessProfileBloc>(
                create: (context) => UserFitnessProfileBloc(
                  diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
                  userRepository: RepositoryProvider.of<UserRepository>(context),
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

  String userInputGoal = ExerciseUtils.maintainWeight;
  String userInputActivityLevel = ExerciseUtils.notVeryActive;
  int userInputStepGoalPerDay = ExerciseUtils.defaultStepGoal;
  double? userInputGoalWeightInLbs;

  TextEditingController userInputStepGoalPerDayController = TextEditingController();

  @override
  void dispose() {
    userInputStepGoalPerDayController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _createUserFitnessProfileBloc = BlocProvider.of<UserFitnessProfileBloc>(context);
    userInputWeight = widget.currentFitnessUserProfile?.weightInLbs;
    userInputHeight = widget.currentFitnessUserProfile?.heightInCm;
    userInputGoal = widget.currentFitnessUserProfile?.goal ?? userInputGoal;
    userInputActivityLevel = widget.currentFitnessUserProfile?.activityLevel ?? userInputActivityLevel;
    userInputStepGoalPerDay = widget.currentFitnessUserProfile?.stepGoalPerDay ?? 10000;
    userInputGoalWeightInLbs = widget.currentFitnessUserProfile?.goalWeightInLbs;

    userInputStepGoalPerDayController.text = userInputStepGoalPerDay.toString();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.currentFitnessUserProfile != null,
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

  _showUserGoalOptionsDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInternal) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: ScreenUtils.getScreenHeight(context) * 0.75,
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1
                        )
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: ExerciseUtils.allGoals.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            onTap: () {
                              setStateInternal(() {
                                userInputGoal = ExerciseUtils.allGoals[index];
                              });
                              setState(() {
                                userInputGoal = ExerciseUtils.allGoals[index];
                              });
                            },
                            tileColor: ExerciseUtils.allGoals[index] == userInputGoal ? Colors.grey.shade200 : null,
                            title: Text(
                              ExerciseUtils.allGoals[index],
                              style: const TextStyle(
                                  color: Colors.teal
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        }
    );
  }

  _showUserActivityLevelOptionsDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInternal) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: ScreenUtils.getScreenHeight(context) * 0.75,
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1
                        )
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: ExerciseUtils.allActivityLevels.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            onTap: () {
                              setStateInternal(() {
                                userInputActivityLevel = ExerciseUtils.allActivityLevels[index];
                              });
                              setState(() {
                                userInputActivityLevel = ExerciseUtils.allActivityLevels[index];
                              });
                            },
                            tileColor: ExerciseUtils.allActivityLevels[index] == userInputActivityLevel ? Colors.grey.shade200 : null,
                            title: Text(
                              ExerciseUtils.allActivityLevels[index],
                              style: const TextStyle(
                                  color: Colors.teal
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        }
    );
  }

  _renderOptionalStepGoalsInput() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Expanded(
                  flex: 5,
                  child: Text(
                    "Daily step goal",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
              ),
              Expanded(
                  flex: 7,
                  child: TextFormField(
                    controller: userInputStepGoalPerDayController,
                    onChanged: (text) {
                      final w = int.parse(text);
                      if (w > ExerciseUtils.maxStepGoal) {
                        SnackbarUtils.showSnackBarShort(context, "Cannot set goal greater than 25000 steps per day!");
                        userInputStepGoalPerDayController.text = userInputStepGoalPerDay.toString();
                      }
                      else {
                        setState(() {
                          userInputStepGoalPerDay = w;
                        });
                      }
                    },
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: "10000",
                      hintStyle: TextStyle(color: Colors.grey),
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
                    "steps",
                    style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                  )
              )
            ],
          ),
        ),
        WidgetUtils.spacer(2.5),
        SliderTheme(
            data: const SliderThemeData(
              overlayColor: Colors.tealAccent,
              valueIndicatorColor: Colors.teal,
            ),
            child: Slider(
              value: userInputStepGoalPerDay.toDouble(),
              max: ExerciseUtils.maxStepGoal.toDouble(),
              divisions: ExerciseUtils.maxStepGoal ~/ 500,
              // label: _getLabel(selectedHoursPerWeek),
              onChanged: (newValue) {
                setState(() {
                  userInputStepGoalPerDay = newValue.toInt();
                  userInputStepGoalPerDayController.text = userInputStepGoalPerDay.toString();
                });
              },
            )
        )
      ],
    );
  }

  _renderOptionalGoalWeightInput() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Goal weight (in lbs)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )
          ),
          Expanded(
              flex: 7,
              child: TextFormField(
                initialValue: widget.currentFitnessUserProfile?.goalWeightInLbs?.toStringAsFixed(2),
                onChanged: (text) {
                  final w = double.parse(text);
                  setState(() {
                    userInputGoalWeightInLbs = w;
                  });
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "150",
                  hintStyle: TextStyle(color: Colors.grey),
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

  _renderUserGoalInput() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Goal",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )
          ),
          Expanded(
              flex: 9,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                ),
                onPressed: () {
                  _showUserGoalOptionsDialog();
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    userInputGoal,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,

                    ),
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }

  _renderUserActivityLevels() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Activity level",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )
          ),
          Expanded(
              flex: 9,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                ),
                onPressed: () {
                  _showUserActivityLevelOptionsDialog();
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    userInputActivityLevel,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
          ),
        ],
      ),
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
            weightInLbs: userInputWeight!,
            goal: userInputGoal,
            activityLevel: userInputActivityLevel,
            stepGoalPerDay: userInputStepGoalPerDay,
            goalWeightInLbs: userInputGoalWeightInLbs,
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
            WidgetUtils.spacer(5),
            _renderUserImage(),
            WidgetUtils.spacer(5),
            _renderUserName(),
            WidgetUtils.spacer(10),
            _renderUserWeight(),
            WidgetUtils.spacer(5),
            _renderUserHeight(),
            WidgetUtils.spacer(5),
            _renderUserGoalInput(),
            WidgetUtils.spacer(5),
            _renderUserActivityLevels(),
            WidgetUtils.spacer(5),
            _renderOptionalGoalWeightInput(),
            WidgetUtils.spacer(5),
            _renderOptionalStepGoalsInput(),
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
                  hintStyle: TextStyle(color: Colors.grey),
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
                  hintStyle: TextStyle(color: Colors.grey),
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
      return ImageUtils.getImage(widget.currentUserProfile.photoUrl, 500, 500);
    }
  }
}