import 'package:flutter_app/src/models/meetups/meetup_availability.dart';

class MiscUtils {

  static List<MeetupAvailabilityUpsert> convertBooleanCellStateMatrixToAvailabilities(
      List<List<bool>> currentUserAvailabilities,
      Map<int, DateTime> timeSegmentToDateTimeMap
  ) {
    List<MeetupAvailabilityUpsert> resultsSoFar = List.empty(growable: true);

    // Assert on expected size
    currentUserAvailabilities.asMap().forEach((dayIntIndex, dayTimeBlockAvailabilities) {
      var hasContinuousWindowStarted = false;
      var intervalStart = 0;
      var j = 0;

      while(j < dayTimeBlockAvailabilities.length) {
        // Contiguous block is now broken! we have a minimal discrete interval
        if (hasContinuousWindowStarted && !dayTimeBlockAvailabilities[j]) {
          final intervalDatetimeStart = timeSegmentToDateTimeMap[intervalStart]!;
          final intervalDateTimeEnd = timeSegmentToDateTimeMap[j]!;
          resultsSoFar
              .add(MeetupAvailabilityUpsert(
            intervalDatetimeStart.add(Duration(days: dayIntIndex)).toUtc(),
            intervalDateTimeEnd.add(Duration(days: dayIntIndex)).toUtc(),
          ));

          hasContinuousWindowStarted = false;
        }

        else if (hasContinuousWindowStarted && j == dayTimeBlockAvailabilities.length - 1 && dayTimeBlockAvailabilities[j]) {
          final intervalDatetimeStart = timeSegmentToDateTimeMap[intervalStart]!;
          final intervalDateTimeEnd = timeSegmentToDateTimeMap[j]!.add(const Duration(minutes: 30)); // we force add 30 mins for the very last interval
          resultsSoFar
              .add(MeetupAvailabilityUpsert(
            intervalDatetimeStart.add(Duration(days: dayIntIndex)).toUtc(),
            intervalDateTimeEnd.add(Duration(days: dayIntIndex)).toUtc(),
          ));

          hasContinuousWindowStarted = false;
          j++;
        }

        else if (dayTimeBlockAvailabilities[j] && !hasContinuousWindowStarted) {
          hasContinuousWindowStarted = true;
          intervalStart = j;
        }

        else {
          j++;
        }

      }
    });

    return resultsSoFar;
  }
}