import 'dart:convert';

import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/supertokens.dart';

class FrontToken {
  static String? tokenInMemory;
  static String _sharedPreferencesKey = "supertokens-flutter-front-token";
  static final ReadWriteMutex _tokenInfoMutex = ReadWriteMutex();
  static Mutex _frontTokenMutex = Mutex();

  static Future<String?> _getFronTokenFromStorage() async {
    if (tokenInMemory == null) {
      FrontToken.tokenInMemory = (await SharedPreferences.getInstance())
          .getString(FrontToken._sharedPreferencesKey);
    }
    return FrontToken.tokenInMemory;
  }

  static Future<String?> _getFrontToken() {
    if (FrontToken.tokenInMemory == null) {
      return Future.value(null);
    }
    return _getFronTokenFromStorage();
  }

  // TODO: parse front token
  static Map<String, dynamic> _parseFrontToken(fronTokenDecoded) {
    var base64Decoded = base64Decode(fronTokenDecoded);
    String decodedString = new String.fromCharCodes(base64Decoded);
    var result = jsonDecode(decodedString);
    return result;
  }

  static Map<String, dynamic>? _getTokenInfo() {
    Map<String, dynamic>? finalReturnValue;

    Future.microtask(() async {
      while (true) {
        String? frontToken = await _getFrontToken();

        if (frontToken == null) {
          var idRefreshToken = IdRefreshToken.getToken();

          if (idRefreshToken == null) {
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
    });
    return finalReturnValue;
  }

  static Map<String, dynamic>? getToken() {
    return _getTokenInfo();
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

  static void setToken(String? frontToken) async {
    await _tokenInfoMutex.acquireWrite();
    await _setFronToken(frontToken);
    _frontTokenMutex.release();
    _tokenInfoMutex.release();
  }

  static Future _removeTokenFromStorage() async {
    (await SharedPreferences.getInstance())
        .remove(FrontToken._sharedPreferencesKey);
    FrontToken.tokenInMemory = null;
  }

  static Future<void> removeToken() async {
    await _tokenInfoMutex.acquireWrite();
    await _removeTokenFromStorage();
    _tokenInfoMutex.release();
    _frontTokenMutex.release();
  }
}
