import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/user_milestone.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/award_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DetailedAchievementView extends StatelessWidget {
  static const String routeName = "view-achievement";

  static Map<String, String> milestoneCategoryToDisplayNamesMap = {
    StepData().name(): "Step",
    DiaryEntryData().name(): "Diary",
    ActivityData().name(): "Activity",
  };

  final PublicUserProfile userProfile;
  final AwardCategory awardCategory;
  final List<UserMilestone> milestonesForCurrentCategory;


  const DetailedAchievementView({
    super.key,
    required this.userProfile,
    required this.awardCategory,
    required this.milestonesForCurrentCategory
  });

  static Route route(
      PublicUserProfile currentUserProfile,
      AwardCategory awardCategory,
      List<UserMilestone> milestones
  ) => MaterialPageRoute<void>(
      settings: const RouteSettings(
          name: routeName
      ),
      builder: (_) =>  DetailedAchievementView(
          userProfile: currentUserProfile,
          awardCategory: awardCategory,
          milestonesForCurrentCategory: milestones
      )
  );

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${milestoneCategoryToDisplayNamesMap[awardCategory.name()]!} achievements",
          style: const TextStyle(color: Colors.teal),),
          iconTheme: const IconThemeData(
            color: Colors.teal,
          ),
      ),
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _renderHeader(),
              WidgetUtils.spacer(5),
              _renderMilestonesTileList(context),
            ],
          ),
        ),
      ),
    );
  }

  _renderMilestonesTileList(BuildContext context) {
    final allMilestonesForCurrentCategory = AwardUtils.achievementCategoryToAllMilestonesMap[awardCategory.name()]!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      children: List.generate(allMilestonesForCurrentCategory.length, (index) {
        final currentMilestone = allMilestonesForCurrentCategory[index];
        // Show everything, show attained in color
        final isCurrentMilestoneAttained = milestonesForCurrentCategory.map((e) => e.name).contains(currentMilestone.name());
        return GestureDetector(
          onTap: () {
            // Show dialog with some deets
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
                          backgroundColor: isCurrentMilestoneAttained ? Colors.teal : Colors.grey.shade300,
                          radius: 25,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: AssetImage(AwardUtils.awardCategoryToIconAssetPathMap[awardCategory.name()]!)
                              ),
                            ),
                          ),
                        ),
                        WidgetUtils.spacer(5),
                        AutoSizeText(
                          AwardUtils.allMilestoneNameToDisplayNames[currentMilestone.name()]!,
                          maxLines: 1,
                          style: TextStyle(
                              color: isCurrentMilestoneAttained ? Colors.teal : Colors.grey,
                              fontSize: 18,
                              // fontWeight: FontWeight.bold
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

  _renderHeader() {
    double percentageValue = milestonesForCurrentCategory.length / (max(1, AwardUtils.achievementCategoryToAllMilestonesMap[awardCategory.name()]!.length));
    int milestonesAttainedLast30Days = milestonesForCurrentCategory
        .where((element) => element.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;
    int milestonesAttainedLast7Days = milestonesForCurrentCategory
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
                  footer: Padding(
                    padding:  const EdgeInsets.all(10.0),
                    child: AutoSizeText(
                      "${milestoneCategoryToDisplayNamesMap[awardCategory.name()]} milestone progress",
                      maxLines: 1,
                      style: const TextStyle(
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
                    "${milestonesForCurrentCategory.length} / ${AwardUtils.achievementCategoryToAllMilestonesMap[awardCategory.name()]!.length} milestones attained",
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
}