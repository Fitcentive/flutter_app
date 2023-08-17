import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/awards_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/award_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_progress_view/detailed_progress_view.dart';
import 'package:flutter_app/src/views/progress/bloc/progress_home_bloc.dart';
import 'package:flutter_app/src/views/progress/bloc/progress_home_event.dart';
import 'package:flutter_app/src/views/progress/bloc/progress_home_state.dart';
import 'package:flutter_app/src/views/user_fitness_profile/user_fitness_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

GlobalKey<ProgressHomeViewState> progressViewStateGlobalKey = GlobalKey();

class ProgressHomeView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const ProgressHomeView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(Key? key, PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<ProgressHomeBloc>(
          create: (context) => ProgressHomeBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            awardsRepository: RepositoryProvider.of<AwardsRepository>(context),
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: ProgressHomeView(
      key: key,
      currentUserProfile: currentUserProfile
    ),
  );

  @override
  State createState() {
    return ProgressHomeViewState();
  }
}

class ProgressHomeViewState extends State<ProgressHomeView> {

  static Map<String, String> progressCategoryToDisplayNameMap = {
    StepData().name(): "Steps",
    DiaryEntryData().name(): "Diary",
    ActivityData().name(): "Activity",
    WeightData().name(): "Weight",
  };

  late ProgressHomeBloc _progressHomeBloc;

  FitnessUserProfile? currentFitnessUserProfile;

  @override
  void initState() {
    super.initState();

    _progressHomeBloc = BlocProvider.of<ProgressHomeBloc>(context);
    _progressHomeBloc.add(FetchProgressInsights(userId: widget.currentUserProfile.userId));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ProgressHomeBloc, ProgressHomeState>(
        listener: (context, state) {
          if (state is ProgressLoaded) {
            currentFitnessUserProfile = state.fitnessUserProfile;
          }
        },
        child: BlocBuilder<ProgressHomeBloc, ProgressHomeState>(
          builder: (context, state) {
            if (state is ProgressLoaded) {
              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WidgetUtils.spacer(5),
                      _userProfileImageView(),
                      WidgetUtils.spacer(10),
                      _renderInsights(state),
                      WidgetUtils.spacer(10),
                      _renderProgressTileList(state),
                    ],
                  ),
                ),
              );
            }
            else {
              if (DeviceUtils.isAppRunningOnMobileBrowser()) {
                return WidgetUtils.progressIndicator();
              }
              else {
                return _renderSkeleton();
              }
            }
          },
        ),
      ),
    );
  }

  _renderSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SkeletonLoader(
            builder: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  WidgetUtils.spacer(5),
                  _userProfileImageView(),
                  WidgetUtils.spacer(10),
                  _renderInsightsStub(),
                ],
              ),
            ),
          ),
          WidgetUtils.spacer(5),
          SkeletonGridLoader(
            builder: Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1
                  )
              ),
              child: GridTile(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 10,
                      color: Colors.redAccent,
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: 70,
                      height: 10,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            items: 4,
            itemsPerRow: 2,
            period: const Duration(seconds: 2),
            highlightColor: Colors.teal,
            direction: SkeletonDirection.ltr,
            childAspectRatio: 1,
          ),
        ],
      ),
    );
  }

  goToUserFitnessProfileView() {
    Navigator.push<FitnessUserProfile>(
        context,
        UserFitnessProfileView.route(widget.currentUserProfile, currentFitnessUserProfile)
    ).then((value) {
      if (value != null) {
        setState(() {
          currentFitnessUserProfile = value;
        });
      }
    });
  }

  Widget _userProfileImageView() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: GestureDetector(
          onTap: () async {},
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 60, 60),
              color: Colors.teal,
            ),
            child: widget.currentUserProfile.photoUrl == null ? const Icon(
              Icons.account_circle_outlined,
              color: Colors.teal,
              size: 120,
            )
                : null,
          ),
        ),
      ),
    );
  }

  _getTextColorFromLevel(int level) {
    switch (level) {
      case 0: return Colors.red;
      case 1: return Colors.orange;
      case 2: return Colors.teal;
    }
  }

  _renderInsightsStub() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AutoSizeText(
            "",
            style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          WidgetUtils.spacer(10),
          const AutoSizeText(
            "Loading...",
            style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          WidgetUtils.spacer(10),
          const AutoSizeText(
            "",
            style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _renderInsights(ProgressLoaded state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            state.insights.userWeightProgressInsight.insight,
            style: TextStyle(
              color: _getTextColorFromLevel(state.insights.userWeightProgressInsight.level),
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          WidgetUtils.spacer(10),
          AutoSizeText(
            state.insights.userDiaryEntryProgressInsight.insight,
            style: TextStyle(
                color: _getTextColorFromLevel(state.insights.userDiaryEntryProgressInsight.level),
                fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          WidgetUtils.spacer(10),
          AutoSizeText(
            state.insights.userActivityMinutesProgressInsight.insight,
            style: TextStyle(
                color: _getTextColorFromLevel(state.insights.userActivityMinutesProgressInsight.level),
                fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _goToDetailedProgressView(AwardCategory category) {
    Navigator
    .push(
        context,
        DetailedProgressView.route(widget.currentUserProfile, category, currentFitnessUserProfile)
    ).then((value) => _progressHomeBloc.add(FetchProgressInsights(userId: widget.currentUserProfile.userId)));
  }

  _renderProgressTileList(ProgressLoaded state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: List.generate(AwardUtils.allProgressCategories.length, (index) {
        final currentCategory = AwardUtils.allProgressCategories[index];
        return GestureDetector(
          onTap: () {
            _goToDetailedProgressView(currentCategory);
          },
          child: IntrinsicHeight(
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: WidgetUtils.skipNulls([
                        CircleAvatar(
                          radius: 50,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: AssetImage(AwardUtils.awardCategoryToIconAssetPathMap[currentCategory.name()]!)
                              ),
                            ),
                          ),
                        ),
                        WidgetUtils.spacer(5),
                        AutoSizeText(
                          progressCategoryToDisplayNameMap[currentCategory.name()]!,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ]),
                    ),
                  ),
                )
            ),
          ),
        );
      }),
    );
  }

}