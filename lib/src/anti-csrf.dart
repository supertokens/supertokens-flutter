import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/src/logger.dart';

class _AntiCSRFInfo {
  String? antiCSRF;
  String? associatedAccessTokenUpdate;

  _AntiCSRFInfo({String? antiCSRFToken, String? associatedAccessTokenUpdate}) {
    this.antiCSRF = antiCSRFToken;
    this.associatedAccessTokenUpdate = associatedAccessTokenUpdate;
  }
}

class AntiCSRF {
  static _AntiCSRFInfo? _antiCSRFInfo;
  static String _sharedPreferencesKey = "supertokens-flutter-anti-csrf";

  static Future<String?> getToken(String? associatedAccessTokenUpdate) async {
    logDebugMessage('AntiCSRF.getToken: Getting token');
    logDebugMessage('AntiCSRF.getToken: associatedAccessTokenUpdate: ${associatedAccessTokenUpdate}');
    if (associatedAccessTokenUpdate == null) {
      logDebugMessage('AntiCSRF.getToken: associated token is null');
      AntiCSRF._antiCSRFInfo = null;
      return null;
    }

    if (AntiCSRF._antiCSRFInfo == null) {
      logDebugMessage('AntiCSRF.getToken: antiCSRFInfo is null');
      SharedPreferences preferences = await SharedPreferences.getInstance();
      String? antiCSRFToken =
          preferences.getString(AntiCSRF._sharedPreferencesKey);
      if (antiCSRFToken == null) {
        return null;
      }

      AntiCSRF._antiCSRFInfo = _AntiCSRFInfo(
          antiCSRFToken: antiCSRFToken,
          associatedAccessTokenUpdate: associatedAccessTokenUpdate);
    } else if (AntiCSRF._antiCSRFInfo?.associatedAccessTokenUpdate != null &&
        AntiCSRF._antiCSRFInfo?.associatedAccessTokenUpdate !=
            associatedAccessTokenUpdate) {
      logDebugMessage('AntiCSRF.getToken: associatedAccessTokenUpdate did not match');
      AntiCSRF._antiCSRFInfo = null;
      return await AntiCSRF.getToken(associatedAccessTokenUpdate);
    }

    return AntiCSRF._antiCSRFInfo?.antiCSRF;
  }

  static Future<void> setToken(
      String antiCSRFToken, String? associatedAccessTokenUpdate) async {
    logDebugMessage('AntiCSRF.setToken: Setting token');
    logDebugMessage('AntiCSRF.setToken: associatedAccessTokenUpdate: ${associatedAccessTokenUpdate}');
    if (associatedAccessTokenUpdate == null) {
      logDebugMessage('AntiCSRF.setToken: associated token is null');
      AntiCSRF._antiCSRFInfo = null;
      return;
    }

    SharedPreferences preferences = await SharedPreferences.getInstance();
    logDebugMessage('AntiCSRF.setToken: setting preferences for: ${AntiCSRF._sharedPreferencesKey}');
    await preferences.setString(AntiCSRF._sharedPreferencesKey, antiCSRFToken);
    await preferences.reload();

    logDebugMessage('AntiCSRF.setToken: storing the token before returning');
    AntiCSRF._antiCSRFInfo = _AntiCSRFInfo(
        antiCSRFToken: antiCSRFToken,
        associatedAccessTokenUpdate: associatedAccessTokenUpdate);
  }

  static Future<void> removeToken() async {
    logDebugMessage('AntiCSRF.removeToken: Removing token');
    logDebugMessage('AntiCSRF.removeToken: Updating preferences');
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(AntiCSRF._sharedPreferencesKey);
    await preferences.reload();
    logDebugMessage('AntiCSRF.removeToken: Setting token to null');
    AntiCSRF._antiCSRFInfo = null;
  }
}
