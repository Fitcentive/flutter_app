import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/awards_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/user_milestone.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/award_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/achievements/bloc/achievements_home_bloc.dart';
import 'package:flutter_app/src/views/achievements/bloc/achievements_home_event.dart';
import 'package:flutter_app/src/views/achievements/bloc/achievements_home_state.dart';
import 'package:flutter_app/src/views/detailed_achievement_view/detailed_achievement_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class AchievementsHomeView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const AchievementsHomeView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<AchievementsHomeBloc>(
          create: (context) => AchievementsHomeBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            awardsRepository: RepositoryProvider.of<AwardsRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: AchievementsHomeView(currentUserProfile: currentUserProfile),
  );

  @override
  State createState() {
    return AchievementsHomeViewState();
  }
}

class AchievementsHomeViewState extends State<AchievementsHomeView> {

  static Map<String, String> awardCategoryToDisplayNameMap = {
    StepData().name(): "Steps",
    DiaryEntryData().name(): "Diary",
    ActivityData().name(): "Activity",
    WeightData().name(): "Weight",
  };

  final Map<AwardCategory, List<UserMilestone>> userAchievementsMap = {};

  late AchievementsHomeBloc _achievementsHomeBloc;

  @override
  void initState() {
    super.initState();

    _achievementsHomeBloc = BlocProvider.of<AchievementsHomeBloc>(context);
    _achievementsHomeBloc.add(FetchAllUserAchievements(userId: widget.currentUserProfile.userId));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AchievementsHomeBloc, AchievementsHomeState>(
        listener: (context, state) {
          if (state is AchievementsLoadedSuccess) {
            userAchievementsMap[StepData()] = state.userMilestones
                .where((element) => element.milestoneCategory == StepData().name())
                .toList();
          }
        },
        child: BlocBuilder<AchievementsHomeBloc, AchievementsHomeState>(
          builder: (context, state) {
            if (state is AchievementsLoadedSuccess) {
              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _renderAchievementsHeader(state),
                      WidgetUtils.spacer(5),
                      _renderAchievementsTileList(state),
                    ],
                  ),
                ),
              );
            }
            else {
              return _renderSkeleton();
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
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Center(
                        child: CircularPercentIndicator(
                            radius: 90.0,
                            lineWidth: 50.0,
                            percent: 0,
                            center: const Text(
                                "",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                    color: Colors.teal
                                )
                            ),
                            footer: const Padding(
                              padding:  EdgeInsets.all(10.0),
                              child: AutoSizeText(
                                "Milestone progress",
                                maxLines: 1,
                                style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            backgroundColor: Colors.grey.shade300,
                            progressColor: Colors.teal
                        ),
                      )
                  ),
                  WidgetUtils.spacer(10),
                  Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AutoSizeText(
                            "",
                            style:  TextStyle(
                                color: Colors.teal
                            ),
                            textAlign: TextAlign.center,
                          ),
                          WidgetUtils.spacer(10),
                          const AutoSizeText(
                            "Loading...",
                            style: TextStyle(
                                color: Colors.teal
                            ),
                            textAlign: TextAlign.center,
                          ),
                          WidgetUtils.spacer(10),
                          const AutoSizeText(
                            "",
                            style: TextStyle(
                                color: Colors.teal
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                  ),
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

  _renderAchievementsHeader(AchievementsLoadedSuccess state) {
    double percentageValue = state.userMilestones.length / AwardUtils.allAchievementMilestones.length;
    int milestonesAttainedLast30Days = state.userMilestones
        .where((element) => element.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;
    int milestonesAttainedLast7Days = state.userMilestones
        .where((element) => element.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: CircularPercentIndicator(
                radius: 90.0,
                lineWidth: 50.0,
                percent: percentageValue, center: Text(
                  "${(percentageValue * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: percentageValue < 0.3 ? Colors.red : (percentageValue < 0.7 ? Colors.orange : Colors.teal)
                  ),
                ),
                footer: const Padding(
                  padding:  EdgeInsets.all(10.0),
                  child: AutoSizeText(
                    "Milestone progress",
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                backgroundColor: Colors.grey.shade300,
                progressColor: percentageValue < 0.3 ? Colors.redAccent : (percentageValue < 0.7 ? Colors.orangeAccent : Colors.teal),
              ),
            )
          ),
          WidgetUtils.spacer(10),
          Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    "${state.userMilestones.length} / ${AwardUtils.allAchievementMilestones.length} milestones attained",
                    style: const TextStyle(
                      color: Colors.teal
                    ),
                    textAlign: TextAlign.center,
                  ),
                  WidgetUtils.spacer(10),
                  AutoSizeText(
                    "$milestonesAttainedLast7Days milestones attained in the last 7 days",
                    style: const TextStyle(
                        color: Colors.teal
                    ),
                    textAlign: TextAlign.center,
                  ),
                  WidgetUtils.spacer(10),
                  AutoSizeText(
                    "$milestonesAttainedLast30Days milestones attained in the last 30 days",
                    style: const TextStyle(
                        color: Colors.teal
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
          ),
        ],
      ),
    );
  }

  _renderAchievementsTileList(AchievementsLoadedSuccess state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: List.generate(AwardUtils.allAchievementCategories.length, (index) {
        final currentCategory = AwardUtils.allAchievementCategories[index];
        final milestonesAttainedForCurrentCategory = state.userMilestones.where((element) => element.milestoneCategory == currentCategory.name());
        final allMilestonesAvailableForCurrentCategory = AwardUtils.achievementCategoryToAllMilestonesMap[currentCategory.name()]!;
        return GestureDetector(
          onTap: () {
            _goToDetailedAchievementsView(currentCategory, milestonesAttainedForCurrentCategory.toList());
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
                          awardCategoryToDisplayNameMap[currentCategory.name()]!,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        WidgetUtils.spacer(5),
                        AutoSizeText(
                          "${milestonesAttainedForCurrentCategory.length} / ${allMilestonesAvailableForCurrentCategory.length} milestones attained",
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 12,
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

  _goToDetailedAchievementsView(AwardCategory currentCategory, List<UserMilestone> milestonesAttained) {
    if (currentCategory.name() == StepData().name()) {
      _achievementsHomeBloc.add(TrackViewDetailedAchievement(ViewDetailedStepAchievements()));
    }
    else if (currentCategory.name() == DiaryEntryData().name()) {
      _achievementsHomeBloc.add(TrackViewDetailedAchievement(ViewDetailedDiaryAchievements()));
    }
    else if (currentCategory.name() == WeightData().name()) {
      _achievementsHomeBloc.add(TrackViewDetailedAchievement(ViewDetailedWeightAchievements()));
    }
    else {
      _achievementsHomeBloc.add(TrackViewDetailedAchievement(ViewDetailedActivityAchievements()));
    }

    Navigator.push(
        context,
        DetailedAchievementView.route(widget.currentUserProfile, currentCategory, milestonesAttained)
    );
  }

}