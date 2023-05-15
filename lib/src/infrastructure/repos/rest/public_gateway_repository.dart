import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;

class PublicGatewayRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/gateway";

  Future<void> enablePremiumForUser(String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/enable-premium"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.accepted) {
      return;
    }
    else {
      throw Exception(
          "enablePremiumForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<String> uploadImage(String filePath, Uint8List rawImage, String accessToken) async {
    var request = http.MultipartRequest('POST', Uri.parse("$BASE_URL/image/upload/$filePath"))
      ..headers["Authorization"] = "Bearer $accessToken"
      ..files.add(http.MultipartFile.fromBytes("file", rawImage, filename: "file"));
    final response = await request.send();
    if (response.statusCode == HttpStatus.ok) {
      return filePath;
    } else {
      throw Exception("uploadImage: Received bad response with status: ${response.statusCode}");
    }
  }

  Future<String> getAdUnitId(bool isDebug, bool isMobileDevice, bool isAndroid, AdType adType,  String accessToken) async {
    if (isDebug) {
      if (isMobileDevice) {
        if (isAndroid) {
          if (adType == AdType.banner) {
            return Future.value(AdUtils.testBannerAdUnitIdAndroid);
          }
          else if (adType == AdType.interstitial) {
            return Future.value(AdUtils.testInterstitialAdUnitIdAndroid);
          }
          else /*if (adType == AdType.native)*/ {
            return Future.value(AdUtils.testNativeAdUnitIdAndroid);
          }
        }
        else {
          if (adType == AdType.banner) {
            return Future.value(AdUtils.testBannerAdUnitIdIos);
          }
          else if (adType == AdType.interstitial) {
            return Future.value(AdUtils.testInterstitialAdUnitIdIos);
          }
          else /*if (adType == AdType.native)*/ {
            return Future.value(AdUtils.testNativeAdUnitIdIos);
          }
        }
      }
      else {
        return Future.value(AdUtils.testBannerAdUnitIdAndroid); // change this
      }
    }
    else {
      if (isMobileDevice) {
        final response = await http.get(
          Uri.parse("$BASE_URL/admob-ad-unit-id?isAndroid=$isAndroid&adType=$adType"),
          headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == HttpStatus.ok) {
          final jsonResponse = jsonDecode(response.body);
          final String result = jsonResponse.toString();
          return result;
        }
        else {
          throw Exception(
              "getAdUnitId: Received bad response with status: ${response.statusCode} and body ${response.body}");
        }
      }
      else {
        return Future.value(AdUtils.testBannerAdUnitIdAndroid); // change this
      }
    }
  }
}