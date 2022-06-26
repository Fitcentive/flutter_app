class DateTimeUtils {

  static int secondsBetweenNowAndEpochTime(int epochTime) {
    return (epochTime - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
  }

}