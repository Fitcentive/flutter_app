import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/diary_card_view.dart';

class MeetupActivitiesTab extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  final Meetup currentMeetup;

  final Map<String, AllDiaryEntries> participantDiaryEntriesMap;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> rawFoodEntries;
  final String selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor;

  final List<PublicUserProfile> selectedMeetupParticipantUserProfiles;


  const MeetupActivitiesTab({
    super.key,
    required this.currentUserProfile,

    required this.currentMeetup,
    required this.participantDiaryEntriesMap,
    required this.rawFoodEntries,
    required this.selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor,

    required this.selectedMeetupParticipantUserProfiles,

  });

  @override
  State<StatefulWidget> createState() {
    return MeetupActivitiesTabState();
  }
}

class MeetupActivitiesTabState extends State<MeetupActivitiesTab> {

  late String selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor;

  @override
  void initState() {
    super.initState();

    selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor = widget.selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor;
  }

  @override
  Widget build(BuildContext context) {
    final diaryEntriesForSelectedUser =
      widget.participantDiaryEntriesMap[selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 25),
      child: Column(
        // physics: const NeverScrollableScrollPhysics(),
        children: [
          _showFilterByDropDown(),
          WidgetUtils.spacer(2.5),
          Expanded(
            child: DiaryCardView(
              currentUserProfile: widget.currentUserProfile,
              foodDiaryEntries: widget.rawFoodEntries,
              allDiaryEntries: diaryEntriesForSelectedUser,
              onCardTapped: () {},
              selectedDate: null,
            ),
          ),
        ],
      ),
    );
  }

  _showFilterByDropDown() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter by",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14
            ),
          ),
          WidgetUtils.spacer(2.5),
          DropdownButton<String>(
              isExpanded: true,
              value: selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor,
              items: widget.selectedMeetupParticipantUserProfiles.map((e) => DropdownMenuItem<String>(
                value: e.userId,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: CircleAvatar(
                          radius: 15,
                          child: Stack(
                            children: WidgetUtils.skipNulls([
                              Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: ImageUtils.getUserProfileImage(e, 500, 500),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 8,
                        child: Text(
                          "${e.firstName} ${e.lastName}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                          ),
                        )
                    )
                  ],
                ),
              )).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedMeetupParticipantUserProfileIdToShowDiaryEntriesFor = newValue;
                  });
                }
              }
          )
        ],
      ),
    );
  }


}