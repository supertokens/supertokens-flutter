import 'package:shared_preferences/shared_preferences.dart';

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
    if (associatedAccessTokenUpdate == null) {
      AntiCSRF._antiCSRFInfo = null;
      return null;
    }

    if (AntiCSRF._antiCSRFInfo == null) {
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
      AntiCSRF._antiCSRFInfo = null;
      return AntiCSRF.getToken(associatedAccessTokenUpdate);
    }

    return AntiCSRF._antiCSRFInfo?.antiCSRF;
  }

  static Future<void> setToken(
      String antiCSRFToken, String? associatedAccessTokenUpdate) async {
    if (associatedAccessTokenUpdate == null) {
      AntiCSRF._antiCSRFInfo = null;
      return;
    }

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(AntiCSRF._sharedPreferencesKey, antiCSRFToken);
    await preferences.reload();

    AntiCSRF._antiCSRFInfo = _AntiCSRFInfo(
        antiCSRFToken: antiCSRFToken,
        associatedAccessTokenUpdate: associatedAccessTokenUpdate);
  }

  static Future<void> removeToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(AntiCSRF._sharedPreferencesKey);
    await preferences.reload();
    AntiCSRF._antiCSRFInfo = null;
  }
}
