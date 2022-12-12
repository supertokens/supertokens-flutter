import 'dart:convert';

import 'package:supertokens/src/errors.dart';
import 'package:supertokens/src/front-token.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/src/utilities.dart';
import 'package:http/http.dart' as http;
import 'package:supertokens/supertokens.dart';

enum Eventype {
  SIGN_OUT,
  REFRESH_SESSION,
  SESSION_CREATED,
  ACCESS_TOKEN_PAYLOAD_UPDATED,
  UNAUTHORISED
}

enum APIAction { SIGN_OUT, REFRESH_TOKEN }

/// Primary class for the supertokens package
/// Use [SuperTokens.initialise] to initialise the package, do this before making any network calls
class SuperTokens {
  static int sessionExpiryStatusCode = 401;
  static bool isInitCalled = false;
  static String refreshTokenUrl = "";
  static String signOutUrl = "";
  static String rid = '';
  static NormalisedInputType? config;

  static void init({
    required String apiDomain,
    String? apiBasePath,
    int sessionExpiredStatusCode = 401,
    String? cookieDomain,
    String? userDefaultdSuiteName,
    Function(Eventype)? eventHandler,
    Function(APIAction, http.Request)? preAPIHook,
    Function(APIAction, http.Request, http.Response)? postAPIHook,
  }) {
    if (SuperTokens.isInitCalled) {
      return;
    }

    SuperTokens.config = NormalisedInputType.normaliseInputType(
        apiDomain,
        apiBasePath,
        sessionExpiredStatusCode,
        cookieDomain,
        userDefaultdSuiteName,
        eventHandler,
        preAPIHook,
        postAPIHook);

    SuperTokens.refreshTokenUrl =
        config!.apiDomain + (config!.apiBasePath ?? '') + "/session/refresh";
    SuperTokens.signOutUrl =
        config!.apiDomain + (config!.apiBasePath ?? '') + "/signout";
    SuperTokens.rid = "session";
    SuperTokens.isInitCalled = true;
  }

  /// Verifies the validity of the URL and appends the refresh path if needed.
  /// Returns `String` URL to be used as a the refresh endpoint URL.
  static String _transformRefreshTokenEndpoint(String refreshTokenEndpoint) {
    if (!refreshTokenEndpoint.startsWith("http") &&
        !refreshTokenEndpoint.startsWith("https")) {
      throw FormatException("URL must start with either http or https");
    }

    try {
      String urlStringToReturn = refreshTokenEndpoint;
      Uri uri = Uri.parse(urlStringToReturn);
      if (uri.path.isEmpty) {
        urlStringToReturn += "/session/refresh";
      } else if (uri.path == "/") {
        urlStringToReturn += "session/refresh";
      }

      Uri.parse(
          urlStringToReturn); // Checking for valid URL after modifications

      return urlStringToReturn;
    } on FormatException catch (e) {
      // Throw the error like this to maintain the original error message for format exceptions
      throw e;
    } catch (e) {
      // Throw with a generic message for any other exceptions
      throw FormatException("Invalid URL provided");
    }
  }

  /// Use this function to verify if a users session is valid
  static Future<bool> doesSessionExist() async {
    String? idRefreshToken = await IdRefreshToken.getToken();
    return idRefreshToken != null;
  }

  static Future<void> signOut(Function(Exception?) completionHandler) async {
    if (!(await doesSessionExist())) {
      SuperTokens.config!.eventHandler(Eventype.SIGN_OUT);
      completionHandler(null);
      return;
    }

    Uri uri;
    try {
      uri = Uri.parse(SuperTokens.signOutUrl);
    } catch (e) {
      completionHandler(SuperTokensException(
          "Please provide a valid apiDomain and apiBasePath"));
      return;
    }

    http.Request signOut = http.Request('post', uri);
    SuperTokens.config!.preAPIHook(APIAction.SIGN_OUT, signOut);

    var resp;

    try {
      resp = await signOut.send();
      if (resp.statusCode >= 300) {
        completionHandler(SuperTokensException(
            "Sign out failed with response code ${resp.statusCode}"));
        return;
      }
      SuperTokens.config!.postAPIHook(APIAction.SIGN_OUT, signOut, resp);
    } catch (e) {}

    try {
      var dataStr = await resp.stream.bytesToString();
      Map<String, dynamic> data = jsonDecode(dataStr);

      if (data['status'] == 'GENERAL_ERROR') {
        completionHandler(SuperTokensException(data['message']));
      }
    } catch (e) {
      completionHandler(SuperTokensException("Invalid sign out resopnse"));
      return;
    }
  }

  static Future<bool> attemptRefreshingSession() async {
    var preRequestIdRefreshToken = await IdRefreshToken.getToken();
    bool shouldRetry = false;
    Exception? exception;

    SuperTokensHttpClient.onUnauthorisedResponse(preRequestIdRefreshToken,
        (unauthResponse, {error}) {
      if (unauthResponse.status == UnauthorisedStatus.API_ERROR) {
        exception = unauthResponse.exception as SuperTokensException;
      }
      shouldRetry = unauthResponse.status == UnauthorisedStatus.RETRY;
    });
    if (exception != null) {
      throw exception!;
    }
    return shouldRetry;
  }

  static String _getUserId() {
    Map<String, dynamic>? frontToken = FrontToken.getToken();
    if (frontToken == null)
      throw SuperTokensException("Session does not exist");
    return frontToken['uid'] as String;
  }

  static Future<Map<String, dynamic>> getAccessTokenPayloadSecurely() async {
    Map<String, dynamic>? frontToken = FrontToken.getToken();
    if (frontToken == null)
      throw SuperTokensException("Session does not exist");
    int accessTokenExpiry = frontToken['ate'] as int;
    Map<String, dynamic> userPayload = frontToken['up'] as Map<String, dynamic>;

    if (accessTokenExpiry < DateTime.now().millisecondsSinceEpoch) {
      bool retry = await SuperTokens.attemptRefreshingSession();

      if (retry)
        return getAccessTokenPayloadSecurely();
      else
        throw SuperTokensException("Could not refresh session");
    }
    return userPayload;
  }
}
