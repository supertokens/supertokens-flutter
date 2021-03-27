import 'package:shared_preferences/shared_preferences.dart';

class IdRefreshToken {
  static String? idRefreshInMemory;
  static String sharedPreferencesKey = "supertokens-flutter-id-refresh-token";

  static Future<String?> getToken() async {
    if (IdRefreshToken.idRefreshInMemory == null) {
      IdRefreshToken.idRefreshInMemory = (await SharedPreferences.getInstance())
          .getString(IdRefreshToken.sharedPreferencesKey);
    }

    if (IdRefreshToken.idRefreshInMemory != null) {
      List<String> splitParts =
          (IdRefreshToken.idRefreshInMemory ?? "").split(";");
      int expiry = int.parse(splitParts[1]);
      int currentTime = DateTime.now().millisecondsSinceEpoch;

      if (expiry < currentTime) {
        await IdRefreshToken.removeToken();
      }
    }

    return IdRefreshToken.idRefreshInMemory;
  }

  static void setToken(String newIdRefreshToken) async {
    if (newIdRefreshToken == "remove") {
      await IdRefreshToken.removeToken();
      return;
    }
    List<String> splitParts = newIdRefreshToken.split(";");
    int expiry = int.parse(splitParts[1]);
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (expiry < currentTime) {
      await IdRefreshToken.removeToken();
    } else {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString(sharedPreferencesKey, newIdRefreshToken);
      preferences.reload();
      IdRefreshToken.idRefreshInMemory = newIdRefreshToken;
    }
  }

  static Future<void> removeToken() async {
    await (await SharedPreferences.getInstance()).remove(sharedPreferencesKey);
    (await SharedPreferences.getInstance())
        .reload(); // To ensure that the removal is synchronised
    IdRefreshToken.idRefreshInMemory = null;
  }
}
