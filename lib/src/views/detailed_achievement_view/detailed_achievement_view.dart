import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/milestone_types.dart';
import 'package:flutter_app/src/models/awards/user_milestone.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/award_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/share_content/share_content_view.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:timeago/timeago.dart' as timeago;

class DetailedAchievementView extends StatelessWidget {
  static const String routeName = "view-achievement";

  static Map<String, String> milestoneCategoryToDisplayNamesMap = {
    StepData().name(): "Step",
    DiaryEntryData().name(): "Diary",
    ActivityData().name(): "Activity",
    WeightData().name(): "Weight",
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
              _renderAchievementExplanation(),
              WidgetUtils.spacer(5),
              _renderMilestonesTileList(context),
            ],
          ),
        ),
      ),
    );
  }

  _renderAchievementExplanation() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: AutoSizeText(
        _getExplanationBasedOnCategory(),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  _getExplanationBasedOnCategory() {
    switch (awardCategory.name()) {
      case "StepData":
        return "Achieve more milestones by simply walking more";
      case "DiaryEntryData":
        return "Achieve more milestones by logging your activities and nutrition";
      case "ActivityData":
        return "Achieve more milestones by logging activities";
      case "WeightData":
        return "Achieve more milestones by consistently logging your weight";
    }
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
            showDialog(
                context: context,
                builder: (context) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: ScreenUtils.getScreenHeight(context) * 0.65,
                      ),
                      child: _renderAchievementSummary(currentMilestone, context),
                    ),
                  );
                }
            );
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
                          _getAchievementMilestoneName(currentMilestone),
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

  _getAchievementMilestoneName(MilestoneType milestone) {
    if (milestone.category().name() == WeightData().name()) {
      return AwardUtils.allMilestoneNameToDisplayNames[milestone.name()]!.substring(2);
    }
    else {
      return AwardUtils.allMilestoneNameToDisplayNames[milestone.name()]!;
    }
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

  _renderAchievementSummary(MilestoneType currentMilestone, BuildContext context) {
    final isCurrentMilestoneAttained = milestonesForCurrentCategory.map((e) => e.name).contains(currentMilestone.name());
    return Card(
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
          child: Container(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetUtils.skipNulls([
                    Center(
                      child: CircleAvatar(
                        backgroundColor: isCurrentMilestoneAttained ? Colors.teal : Colors.grey.shade300,
                        radius: 40,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: AssetImage(AwardUtils.awardCategoryToIconAssetPathMap[awardCategory.name()]!)
                            ),
                          ),
                        ),
                      ),
                    ),
                    WidgetUtils.spacer(5),
                    AutoSizeText(
                      _getAchievementMilestoneName(currentMilestone),
                      maxLines: 1,
                      style: TextStyle(
                        color: isCurrentMilestoneAttained ? Colors.teal : Colors.grey,
                        fontSize: 18,
                        // fontWeight: FontWeight.bold
                      ),
                    ),
                    WidgetUtils.spacer(5),
                    _renderMilestoneAttainedAtTextIfNeeded(isCurrentMilestoneAttained, currentMilestone),
                    WidgetUtils.spacer(5),
                    _renderShareButtonIfAttained(isCurrentMilestoneAttained, currentMilestone, context),
                  ]),
                ),
              ),
            ),
          ),
        )
    );
  }

  _goToShareContentView(MilestoneType currentMilestone, BuildContext context) {
    String text = "I just attained a milestone for reaching ${AwardUtils.allMilestoneNameToDisplayNames[currentMilestone.name()]!}."
        " Join me as I try to get 'em all!";
    final attainedMilestone = milestonesForCurrentCategory.where((element) => element.name == currentMilestone.name()).first;
    final Widget widget = ConstrainedBox(
        key: widgetToCaptureKey,
        constraints: const BoxConstraints(maxHeight: 250),
        child: Column(
          children: [
            Center(
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
                      image: ImageUtils.getUserProfileImage(userProfile, 60, 60),
                      color: Colors.teal,
                    ),
                    child: userProfile.photoUrl == null ? const Icon(
                      Icons.account_circle_outlined,
                      color: Colors.teal,
                      size: 120,
                    ) : null,
                  ),
                ),
              ),
            ),
            WidgetUtils.spacer(15),
            Row(
              children: [
                const Expanded(
                  flex: 1,
                    child: Text("")
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 35,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: AssetImage(AwardUtils.awardCategoryToIconAssetPathMap[awardCategory.name()]!)
                          ),
                        ),
                      ),
                    ),
                  )
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          _getAchievementMilestoneName(currentMilestone),
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            // fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          DateFormat("MMM dd yyyy").format(attainedMilestone.createdAt),
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 15,
                            // fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  )
                ),
                const Expanded(
                    flex: 1,
                    child: Text("")
                ),
              ],
            )
          ],
        ),
    );
    Navigator.push(
        context,
        ShareContentView.route(userProfile, text, widget)
    ).then((value) => Navigator.pop(context));
  }

  _renderShareButtonIfAttained(bool isCurrentMilestoneAttained, MilestoneType currentMilestone, BuildContext context) {
    if (isCurrentMilestoneAttained) {
      return ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          _goToShareContentView(currentMilestone, context);
        },
        child: const Text(
            "Share milestone",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white
            )),
      );
    }
  }

  _renderMilestoneAttainedAtTextIfNeeded(bool isCurrentMilestoneAttained, MilestoneType currentMilestone) {
    if (!isCurrentMilestoneAttained) {
      return const AutoSizeText(
        "You are yet to achieve this milestone",
        maxLines: 1,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 15,
          // fontWeight: FontWeight.bold
        ),
      );
    }
    else {
      final attainedMilestone = milestonesForCurrentCategory.where((element) => element.name == currentMilestone.name()).first;
      return AutoSizeText(
        "You attained this milestone ${timeago.format(attainedMilestone.createdAt)}",
        maxLines: 1,
        style: TextStyle(
          color: isCurrentMilestoneAttained ? Colors.teal : Colors.grey,
          fontSize: 15,
          // fontWeight: FontWeight.bold
        ),
      );
    }
  }

}