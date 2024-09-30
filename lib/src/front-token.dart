import 'dart:convert';

import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/src/utilities.dart';
import 'package:supertokens_flutter/supertokens.dart';
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/logger.dart';

class FrontToken {
  static String? tokenInMemory;
  static String _sharedPreferencesKey = "supertokens-flutter-front-token";
  static final ReadWriteMutex _tokenInfoMutex = ReadWriteMutex();
  static Mutex _frontTokenMutex = Mutex();

  static Future<String?> _getFronTokenFromStorage() async {
    logDebugMessage('FrontToken._getFronTokenFromStorage: Getting front token from storage');
    if (tokenInMemory == null) {
      logDebugMessage('FrontToken._getFronTokenFromStorage: Fetching token from shared preferences');
      String? token = (await SharedPreferences.getInstance())
          .getString(FrontToken._sharedPreferencesKey);
      logDebugMessage('FrontToken._getFronTokenFromStorage: Setting in memory: ${token}');
      FrontToken.tokenInMemory = token;
    }
    logDebugMessage('FrontToken._getFronTokenFromStorage: token from memory: ${FrontToken.tokenInMemory}');
    return FrontToken.tokenInMemory;
  }

  static Future<String?> _getFrontToken() async {
    logDebugMessage('FrontToken._getFrontToken: Getting front token');
    LocalSessionState localSessionState =
        await SuperTokensUtils.getLocalSessionState();
    if (localSessionState.status == LocalSessionStateStatus.NOT_EXISTS) {
      logDebugMessage('FrontToken._getFrontToken: status is not exists');
      return null;
    }
    logDebugMessage('FrontToken._getFrontToken: Returning token from storage');
    return _getFronTokenFromStorage();
  }

  static Map<String, dynamic> _parseFrontToken(fronTokenDecoded) {
    logDebugMessage('FrontToken._parseFrontToken: parsing front token: ${fronTokenDecoded}');
    var base64Decoded = base64Decode(fronTokenDecoded);
    String decodedString = utf8.decode(base64Decoded);
    var result = jsonDecode(decodedString);
    logDebugMessage('FrontToken._parseFrontToken: decoded value: ${result}');
    return result;
  }

  static Future<Map<String, dynamic>?> _getTokenInfo() async {
    Map<String, dynamic>? finalReturnValue;
    logDebugMessage('FrontToken._getTokenInfo: getting token info');

    while (true) {
      String? frontToken = await _getFrontToken();
      logDebugMessage('FrontToken._getTokenInfo: got frontToken: ${frontToken}');

      if (frontToken == null) {
        logDebugMessage('FrontToken._getTokenInfo: Fetching local session state since token is null');
        LocalSessionState localSessionState =
            await SuperTokensUtils.getLocalSessionState();
        if (localSessionState.status == LocalSessionStateStatus.EXISTS) {
          logDebugMessage('FrontToken._getTokenInfo: local session state status is exists');
          await _frontTokenMutex.acquire();
        } else {
          logDebugMessage('FrontToken._getTokenInfo: local session state status is not exists');
          finalReturnValue = null;
          if (_frontTokenMutex.isLocked) {
            _frontTokenMutex.release();
          }
          logDebugMessage('FrontToken._getTokenInfo: Breaking out of the loop');
          break;
        }
      } else {
        logDebugMessage('FrontToken._getTokenInfo: Parsing and returning token');
        finalReturnValue = _parseFrontToken(frontToken);
        if (_frontTokenMutex.isLocked) {
          _frontTokenMutex.release();
        }
        break;
      }
    }
    return finalReturnValue;
  }

  static Future<Map<String, dynamic>?> getToken() async {
    return await _getTokenInfo();
  }

  static Future _setFrontTokenToStorage(String? frontToken) async {
    logDebugMessage('FrontToken._setFrontTokenToStorage: Setting front token in storage');
    logDebugMessage('FrontToken._setFrontTokenToStorage: frontToken: ${frontToken}');
    var instance = await SharedPreferences.getInstance();
    if (frontToken == null) {
      logDebugMessage('FrontToken._setFrontTokenToStorage: token is null, removing from preferences and memory');
      instance.remove(FrontToken._sharedPreferencesKey);
      FrontToken.tokenInMemory = null;
    } else {
      logDebugMessage('FrontToken._setFrontTokenToStorage: Setting updated token in preferences and memory');
      instance.setString(FrontToken._sharedPreferencesKey, frontToken);
      FrontToken.tokenInMemory = frontToken;
    }
  }

  static Future _setFronToken(String? frontToken) async {
    logDebugMessage('FrontToken._setFronToken: Setting front token: ${frontToken}');
    String? oldToken = await _getFronTokenFromStorage();
    logDebugMessage('FrontToken._setFronToken: oldToken: ${oldToken}');

    if (oldToken != null && frontToken != null) {
      logDebugMessage('FrontToken._setFronToken: Both oldToken and frontToken are non null');
      Map<String, dynamic> oldTokenPayload =
          _parseFrontToken(oldToken)['up'] as Map<String, dynamic>;
      Map<String, dynamic> newTokenPayload =
          _parseFrontToken(frontToken)['up'] as Map<String, dynamic>;

      String oldPayloadString = oldTokenPayload.toString();
      String newPayloadString = newTokenPayload.toString();

      if (oldPayloadString != newPayloadString) {
        logDebugMessage('FrontToken._setFronToken: payloads do not match, sending event: ACCESS_TOKEN_PAYLOAD_UPDATED');
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
    logDebugMessage('FrontToken.setItem: Setting item for frontToken');

    if (frontToken == "remove") {
      logDebugMessage('FrontToken.setItem: Removing front token');
      await FrontToken.removeToken();
      return;
    }

    try {
      await _frontTokenMutex.acquire();
      logDebugMessage('FrontToken.setItem: Setting front token');
      await FrontToken._setFronToken(frontToken);
    } finally {
      if (_frontTokenMutex.isLocked) {
        _frontTokenMutex.release();
      }
    }
  }

  static Future<bool> doesTokenExist() async {
    logDebugMessage('FrontToken.doesTokenExist: Checking if token exists');
    try {
      await _frontTokenMutex.acquire();
      var frontToken = await FrontToken._getFronTokenFromStorage();
      logDebugMessage('FrontToken.doesTokenExist: frontToken: ${frontToken}');
      return frontToken != null;
    } finally {
      if (_frontTokenMutex.isLocked) {
        _frontTokenMutex.release();
      }
    }
  }

  static Future _removeTokenFromStorage() async {
    logDebugMessage('FrontToken._removeTokenFromStorage: Removing token from preferences and memory');
    (await SharedPreferences.getInstance())
        .remove(FrontToken._sharedPreferencesKey);
    FrontToken.tokenInMemory = null;
  }

  static Future<void> removeToken() async {
    logDebugMessage('FrontToken.removeToken: Removing token');
    await _tokenInfoMutex.acquireWrite();
    await _removeTokenFromStorage();
    logDebugMessage('FrontToken.removeToken: Setting access and refresh token to empty value');
    await Utils.setToken(TokenType.ACCESS, "");
    await Utils.setToken(TokenType.REFRESH, "");
    logDebugMessage('FrontToken.removeToken: Removing token from AntiCSRF');
    await AntiCSRF.removeToken();
    if (_tokenInfoMutex.isLocked) {
      _tokenInfoMutex.release();
    }
    if (_frontTokenMutex.isLocked) {
      _frontTokenMutex.release();
    }
  }
}
