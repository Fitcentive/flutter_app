class DateTimeUtils {

  static int secondsBetweenNowAndEpochTime(int epochTime) {
    return (epochTime - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
  }

}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month
        && day == other.day;
  }
}