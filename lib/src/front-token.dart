import 'dart:convert';

import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/src/utilities.dart';
import 'package:supertokens_flutter/supertokens.dart';

class FrontToken {
  static String? tokenInMemory;
  static String _sharedPreferencesKey = "supertokens-flutter-front-token";
  static final ReadWriteMutex _tokenInfoMutex = ReadWriteMutex();
  static Mutex _frontTokenMutex = Mutex();

  static Future<String?> _getFronTokenFromStorage() async {
    if (tokenInMemory == null) {
      String? token = (await SharedPreferences.getInstance())
          .getString(FrontToken._sharedPreferencesKey);
      FrontToken.tokenInMemory = token;
    }
    return FrontToken.tokenInMemory;
  }

  static Future<String?> _getFrontToken() async {
    LocalSessionState localSessionState =
        await SuperTokensUtils.getLocalSessionState();
    if (localSessionState.status == LocalSessionStateStatus.NOT_EXISTS) {
      return null;
    }
    return _getFronTokenFromStorage();
  }

  static Map<String, dynamic> _parseFrontToken(fronTokenDecoded) {
    var base64Decoded = base64Decode(fronTokenDecoded);
    String decodedString = new String.fromCharCodes(base64Decoded);
    var result = jsonDecode(decodedString);
    return result;
  }

  static Future<Map<String, dynamic>?> _getTokenInfo() async {
    Map<String, dynamic>? finalReturnValue;

    while (true) {
      String? frontToken = await _getFrontToken();

      if (frontToken == null) {
        LocalSessionState localSessionState =
            await SuperTokensUtils.getLocalSessionState();

        if (localSessionState.status == LocalSessionStateStatus.EXISTS) {
          _frontTokenMutex.acquire();
        } else {
          finalReturnValue = null;
          break;
        }
      } else {
        finalReturnValue = _parseFrontToken(frontToken);
        break;
      }
    }
    return finalReturnValue;
  }

  static Future<Map<String, dynamic>?> getToken() async {
    return await _getTokenInfo();
  }

  static Future _setFrontTokenToStorage(String? frontToken) async {
    var instance = await SharedPreferences.getInstance();
    if (frontToken == null) {
      instance.remove(FrontToken._sharedPreferencesKey);
      FrontToken.tokenInMemory = null;
    } else {
      instance.setString(FrontToken._sharedPreferencesKey, frontToken);
      FrontToken.tokenInMemory = frontToken;
    }
  }

  static Future _setFronToken(String? frontToken) async {
    String? oldToken = await _getFronTokenFromStorage();

    if (oldToken != null && frontToken != null) {
      Map<String, dynamic> oldTokenPayload =
          _parseFrontToken(oldToken)['up'] as Map<String, dynamic>;
      Map<String, dynamic> newTokenPayload =
          _parseFrontToken(frontToken)['up'] as Map<String, dynamic>;

      String oldPayloadString = oldTokenPayload.toString();
      String newPayloadString = newTokenPayload.toString();

      if (oldPayloadString != newPayloadString) {
        SuperTokens.config.eventHandler(Eventype.ACCESS_TOKEN_PAYLOAD_UPDATED);
      }
    }

    _setFrontTokenToStorage(frontToken);
  }

  static Future<void> setItem(String frontToken) async {
    // We update the refresh attempt info here as well, since this means that we've updated the session in some way
    // This could be both by a refresh call or if the access token was updated in a custom endpoint
    // By saving every time the access token has been updated, we cause an early retry if
    // another request has failed with a 401 with the previous access token and the token still exists.
    // Check the start and end of onUnauthorisedResponse
    // As a side-effect we reload the anti-csrf token to check if it was changed by another tab.
    await SuperTokensUtils.saveLastAccessTokenUpdate();

    if (frontToken == "remove") {
      await FrontToken.removeToken();
      return;
    }

    FrontToken._setFronToken(frontToken);
  }

  static Future<bool> doesTokenExist() async {
    var frontToken = await FrontToken._getFronTokenFromStorage();
    return frontToken != null;
  }

  static Future _removeTokenFromStorage() async {
    (await SharedPreferences.getInstance())
        .remove(FrontToken._sharedPreferencesKey);
    FrontToken.tokenInMemory = null;
  }

  static Future<void> removeToken() async {
    await _tokenInfoMutex.acquireWrite();
    await _removeTokenFromStorage();
    if (_tokenInfoMutex.isLocked) {
      _tokenInfoMutex.release();
    }
    if (_frontTokenMutex.isLocked) {
      _frontTokenMutex.release();
    }
  }
}
