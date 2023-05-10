class AdUtils {
  // More info on AdMob setup - https://developers.google.com/admob/flutter/quick-start
  // These are all test Ad Unit Ids - for the real one, we query our backend via public-gateway

  static const String testBannerAdUnitIdAndroid = "ca-app-pub-3940256099942544/6300978111";
  static const String testBannerAdUnitIdIos = "ca-app-pub-3940256099942544/2934735716";

  static const String testInterstitialAdUnitIdAndroid = "ca-app-pub-3940256099942544/1033173712";
  static const String testInterstitialAdUnitIdIos = "ca-app-pub-3940256099942544/4411468910";

  static const String testNativeAdUnitIdAndroid = "ca-app-pub-3940256099942544/2247696110";
  static const String testNativeAdUnitIdIos = "ca-app-pub-3940256099942544/3986624511";

  static const int adRefreshTimeInSeconds = 300; // 5 minutes
}

enum AdType { banner, interstitial, native }
