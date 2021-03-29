import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class _AntiCSRFInfo {
  String antiCSRF;
  String idRefreshToken;

  _AntiCSRFInfo({String antiCSRFToken, String associatedIdRefreshToken}) {
    this.antiCSRF = antiCSRFToken;
    this.idRefreshToken = associatedIdRefreshToken;
  }
}

class AntiCSRF {
  static _AntiCSRFInfo _antiCSRFInfo;
  static String _sharedPreferencesKey = "supertokens-flutter-anti-csrf";

  static Future<String> getToken(String associatedIdRefreshToken) async {
    if (associatedIdRefreshToken == null) {
      AntiCSRF._antiCSRFInfo = null;
      return null;
    }

    if (AntiCSRF._antiCSRFInfo == null) {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      String antiCSRFToken =
          preferences.getString(AntiCSRF._sharedPreferencesKey);
      if (antiCSRFToken == null) {
        return null;
      }

      AntiCSRF._antiCSRFInfo = _AntiCSRFInfo(
          antiCSRFToken: antiCSRFToken,
          associatedIdRefreshToken: associatedIdRefreshToken);
    } else if (AntiCSRF._antiCSRFInfo?.idRefreshToken != null &&
        AntiCSRF._antiCSRFInfo?.idRefreshToken != associatedIdRefreshToken) {
      AntiCSRF._antiCSRFInfo = null;
      return AntiCSRF.getToken(associatedIdRefreshToken);
    }

    return AntiCSRF._antiCSRFInfo.antiCSRF;
  }

  static Future<void> setToken(
      String antiCSRFToken, String associatedIdRefreshToken) async {
    if (associatedIdRefreshToken == null) {
      AntiCSRF._antiCSRFInfo = null;
      return;
    }

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(AntiCSRF._sharedPreferencesKey, antiCSRFToken);
    await preferences.reload();

    AntiCSRF._antiCSRFInfo = _AntiCSRFInfo(
        antiCSRFToken: antiCSRFToken,
        associatedIdRefreshToken: associatedIdRefreshToken);
  }

  static Future<void> removeToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(AntiCSRF._sharedPreferencesKey);
    await preferences.reload();
    AntiCSRF._antiCSRFInfo = null;
  }
}
