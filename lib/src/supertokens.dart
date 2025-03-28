import 'dart:convert';
import 'package:supertokens_flutter/src/errors.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/utilities.dart';
import 'package:http/http.dart' as http;
import 'package:supertokens_flutter/src/supertokens-http-client.dart';
import 'package:supertokens_flutter/src/logger.dart';

enum Eventype {
  SIGN_OUT,
  REFRESH_SESSION,
  SESSION_CREATED,
  ACCESS_TOKEN_PAYLOAD_UPDATED,
  UNAUTHORISED
}

enum APIAction { SIGN_OUT, REFRESH_TOKEN }

enum SuperTokensTokenTransferMethod { COOKIE, HEADER }

extension ValueExtension on SuperTokensTokenTransferMethod {
  String getValue() {
    switch (this) {
      case SuperTokensTokenTransferMethod.HEADER:
        return "header";
      case SuperTokensTokenTransferMethod.COOKIE:
        return "cookie";
    }
  }
}

/// Primary class for the supertokens package
/// Use [SuperTokens.initialise] to initialise the package, do this before making any network calls
class SuperTokens {
  static int sessionExpiryStatusCode = 401;
  static bool isInitCalled = false;
  static String refreshTokenUrl = "";
  static String signOutUrl = "";
  static String rid = "";
  static late NormalisedInputType config;

  static void init({
    required String apiDomain,
    String? apiBasePath,
    int? maxRetryAttemptsForSessionRefresh,
    int sessionExpiredStatusCode = 401,
    String? sessionTokenBackendDomain,
    SuperTokensTokenTransferMethod? tokenTransferMethod,
    Function(Eventype)? eventHandler,
    http.Request Function(APIAction, http.Request)? preAPIHook,
    Function(APIAction, http.Request, http.Response)? postAPIHook,
    bool? enableDebugLogs,
  }) {
    if (SuperTokens.isInitCalled) {
      return;
    }

    // Enable debug mode if that is specified by the user.
    if (enableDebugLogs != null && enableDebugLogs) {
      enableLogging();
    }

    logDebugMessage("SuperTokens.init: Started SuperTokens with debug logging (supertokens.init called)");

    SuperTokens.config = NormalisedInputType.normaliseInputType(
      apiDomain,
      apiBasePath,
      sessionExpiredStatusCode,
      maxRetryAttemptsForSessionRefresh,
      sessionTokenBackendDomain,
      tokenTransferMethod,
      eventHandler,
      preAPIHook,
      postAPIHook,
    );

    logDebugMessage('SuperTokens.init: config: ${jsonEncode(config.toJson())}');

    SuperTokens.refreshTokenUrl =
        config.apiDomain + (config.apiBasePath ?? '') + "/session/refresh";
    SuperTokens.signOutUrl =
        config.apiDomain + (config.apiBasePath ?? '') + "/signout";
    SuperTokens.rid = "session";

    logDebugMessage('SuperTokens.init: refreshTokenUrl: ${refreshTokenUrl}');
    logDebugMessage('SuperTokens.init: signOutUrl: ${signOutUrl}');
    logDebugMessage('SuperTokens.init: rid: ${rid}');

    SuperTokens.isInitCalled = true;
  }

  /// Use this function to verify if a users session is valid
  static Future<bool> doesSessionExist() async {
    Map<String, dynamic>? tokenInfo = await FrontToken.getToken();

    logDebugMessage('SuperTokens.doesSessionExist: Got token info: ${jsonEncode(tokenInfo)}');
    if (tokenInfo == null) {
      logDebugMessage('SuperTokens.doesSessionExist: token info is null');
      return false;
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    int accessTokenExpiry = tokenInfo["ate"];

    if (accessTokenExpiry != null && accessTokenExpiry < now) {
      logDebugMessage('SuperTokens.doesSessionExist: access token has expired');
      LocalSessionState preRequestLocalSessionState =
          await SuperTokensUtils.getLocalSessionState();

      var resp =
          await Client.onUnauthorisedResponse(preRequestLocalSessionState);

      if (resp.error != null) {
        // Here we dont throw the error and instead return false, because
        // otherwise users would have to use a try catch just to call doesSessionExist
        return false;
      }

      return resp.status == UnauthorisedStatus.RETRY;
    }

    return true;
  }

  static Future<void> signOut({Function(Exception?)? completionHandler}) async {
    logDebugMessage('SuperTokens.signOut: Signing out user');
    if (!(await doesSessionExist())) {
      logDebugMessage('SuperTokens.signOut: Session does not exist');
      SuperTokens.config.eventHandler(Eventype.SIGN_OUT);
      if (completionHandler != null) {
        logDebugMessage('SuperTokens.signOut: Calling completionHandler');
        completionHandler(null);
      }
      return;
    }

    Uri uri;
    try {
      uri = Uri.parse(SuperTokens.signOutUrl);
    } catch (e) {
      if (completionHandler != null) {
        completionHandler(SuperTokensException(
            "Please provide a valid apiDomain and apiBasePath"));
      }
      return;
    }

    logDebugMessage('SuperTokens.signOut: Using signOutUrl: ${uri}');
    http.Request signOut = http.Request('post', uri);
    signOut = SuperTokens.config.preAPIHook(APIAction.SIGN_OUT, signOut);

    late http.StreamedResponse resp;

    try {
      Client client = Client();
      resp = await client.send(signOut);
      if (resp.statusCode >= 300) {
        if (completionHandler != null) {
          completionHandler(SuperTokensException(
              "Sign out failed with response code ${resp.statusCode}"));
        }
        return;
      }
      http.Response response = await http.Response.fromStream(resp);
      SuperTokens.config.postAPIHook(APIAction.SIGN_OUT, signOut, response);

      var dataStr = response.body;
      Map<String, dynamic> data = jsonDecode(dataStr);

      if (data['status'] == 'GENERAL_ERROR') {
        if (completionHandler != null) {
          completionHandler(SuperTokensGeneralError(data['message']));
        }
      }
    } catch (e) {
      if (completionHandler != null) {
        completionHandler(SuperTokensException("Invalid sign out resopnse"));
      }
      return;
    }
  }

  static Future<bool> attemptRefreshingSession() async {
    logDebugMessage('SuperTokens.attemptRefreshingSession: Attempting to refresh session');
    LocalSessionState preRequestLocalSessionState =
        await SuperTokensUtils.getLocalSessionState();
    bool shouldRetry = false;
    Exception? exception;

    dynamic resp =
        await Client.onUnauthorisedResponse(preRequestLocalSessionState);
    if (resp is UnauthorisedResponse) {
      logDebugMessage('SuperTokens.attemptRefreshingSession: Got unauthorised response');
      if (resp.status == UnauthorisedStatus.API_ERROR) {
        logDebugMessage('SuperTokens.attemptRefreshingSession: Got API error');
        exception = resp.error as SuperTokensException;
      } else {
        shouldRetry = resp.status == UnauthorisedStatus.RETRY;
        logDebugMessage('SuperTokens.attemptRefreshingSession: shouldRetry: ${shouldRetry}');
      }
    }
    if (exception != null) {
      throw exception;
    }
    return shouldRetry;
  }

  static Future<String> getUserId() async {
    Map<String, dynamic>? frontToken = await FrontToken.getToken();
    if (frontToken == null)
      throw SuperTokensException("Session does not exist");
    return frontToken['uid'] as String;
  }

  static Future<Map<String, dynamic>> getAccessTokenPayloadSecurely() async {
    Map<String, dynamic>? frontToken = await FrontToken.getToken();
    if (frontToken == null)
      throw SuperTokensException("Session does not exist");
    int accessTokenExpiry = frontToken['ate'] as int;
    Map<String, dynamic> userPayload = frontToken['up'] as Map<String, dynamic>;

    if (accessTokenExpiry < DateTime.now().millisecondsSinceEpoch) {
      logDebugMessage('SuperTokens.getAccessTokenPayloadSecurely: access token has expired, trying to refresh');
      bool retry = await SuperTokens.attemptRefreshingSession();

      if (retry) {
        logDebugMessage('SuperTokens.getAccessTokenPayloadSecurely: Retry was successful, extracting payload');
        return getAccessTokenPayloadSecurely();
      }
      else
        throw SuperTokensException("Could not refresh session");
    }
    return userPayload;
  }

  static Future<String?> getAccessToken() async {
    if (await doesSessionExist()) {
      return await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
    }
    return null;
  }
}
