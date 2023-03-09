import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/constants.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/normalised-url-domain.dart';
import 'package:supertokens_flutter/src/normalised-url-path.dart';
import 'package:dio/dio.dart' as Dio;

import '../supertokens.dart';

enum LocalSessionStateStatus { NOT_EXISTS, EXISTS }

enum TokenType { ACCESS, REFRESH }

extension TokenTypeExtension on TokenType {
  String getStorageName() {
    switch (this) {
      case TokenType.ACCESS:
        return ACCESS_TOKEN_NAME;
      case TokenType.REFRESH:
        return REFRESH_TOKEN_NAME;
    }
  }
}

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

class LocalSessionState {
  LocalSessionStateStatus status;
  String? lastAccessTokenUpdate;

  LocalSessionState({
    required this.status,
    required this.lastAccessTokenUpdate,
  });
}

class SuperTokensUtils {
  /// Returns the domain of the provided url if valid
  ///
  /// Throws [FormatException] if the url is invalid or does not have a http/https scheme
  static String getApiDomain(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      List<String> splitArray = url.split("/");
      List<String> apiDomainArray = [];
      for (int i = 0; i <= 2; i++) {
        try {
          apiDomainArray.add(splitArray[i]);
        } catch (e) {
          throw new FormatException(
              "Invalid URL provided for refresh token endpoint");
        }
      }
      return apiDomainArray.join("/");
    } else {
      throw new FormatException(
          "Refresh token endpoint must start with http or https");
    }
  }

  /// Returns a copy of the provided request object as a [http.BaseRequest]
  ///
  /// Does not support [StreamedRequest], throws [Exception] if request type is not [http.Request] or [http.MultipartRequest]
  static http.BaseRequest copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('copying streamed requests is not supported');
    } else {
      throw Exception('request type is unknown, cannot copy');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }

  static Future<void> storeInStorage(String name, String value) async {
    String storageKey = "st-storage-item-$name";
    SharedPreferences instance = await SharedPreferences.getInstance();

    if (value.isEmpty) {
      await instance.remove(storageKey);
      return;
    }

    await instance.setString(storageKey, value);
  }

  static Future<void> saveLastAccessTokenUpdate() async {
    int now = DateTime.now().millisecondsSinceEpoch;

    await storeInStorage(lastAccessTokenStorageKey, "$now");
    await storeInStorage("sIRTFrontend", "");
  }

  static Future<String?> getFromStorage(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    var itemInStorage = instance.getString("st-storage-item-$name");

    if (itemInStorage == null) {
      return null;
    }

    return itemInStorage;
  }

  static Future<LocalSessionState> getLocalSessionState() async {
    var lastAccessTokenUpdate = await getFromStorage(lastAccessTokenStorageKey);
    // ! DO NOT REMOVE THE BELOW FOR EACH LOOP, REMOVING THIS BREAKS THRE TESTS
    var instance = await SharedPreferences.getInstance();
    instance.getKeys().forEach((element) {});
    var frontTokenExists = await FrontToken.doesTokenExist();

    if (frontTokenExists && lastAccessTokenUpdate != null) {
      return LocalSessionState(
          status: LocalSessionStateStatus.EXISTS,
          lastAccessTokenUpdate: lastAccessTokenUpdate);
    } else {
      return LocalSessionState(
          status: LocalSessionStateStatus.NOT_EXISTS,
          lastAccessTokenUpdate: null);
    }
  }

  static void fireSessionUpdateEventsIfNecessary({
    required bool wasLoggedIn,
    required int status,
    required String? frontTokenFromResponse,
  }) {
    // In case we've received a 401 that didn't clear the session (e.g.: we've sent no session token, or we should try refreshing)
    // then onUnauthorised will handle firing the UNAUTHORISED event if necessary
    // In some rare cases (where we receive a 401 that also clears the session) this will fire the event twice.
    // This may be considered a bug, but it is the existing behaviour before the rework
    if (frontTokenFromResponse == null) {
      return;
    }

    // if the current endpoint clears the session it'll set the front-token to remove
    // any other update means it's created or updated.
    bool frontTokenExistsAfter = frontTokenFromResponse != "remove";

    if (wasLoggedIn) {
      // we check for wasLoggedIn cause we don't want to fire an event
      // unnecessarily on first app load or if the user tried
      // to query an API that returned 401 while the user was not logged in...
      if (!frontTokenExistsAfter) {
        if (status == SuperTokens.config.sessionExpiredStatusCode) {
          SuperTokens.config.eventHandler(Eventype.UNAUTHORISED);
        } else {
          SuperTokens.config.eventHandler(Eventype.SIGN_OUT);
        }
      }
    } else if (frontTokenExistsAfter) {
      SuperTokens.config.eventHandler(Eventype.SESSION_CREATED);
    }
  }
}

class Utils {
  static bool isIPAddress(String input) {
    RegExp regex = RegExp(
        r"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");
    return regex.hasMatch(input);
  }

  static bool shouldDoInterceptions(
      String toCheckURL, String apiDomain, String? cookieDomain) {
    String _toCheckURL =
        NormalisedURLDomain.normaliseUrlDomainOrThrowError(toCheckURL);
    String _apiDomain = apiDomain;
    Uri urlObject;
    String hostname;
    try {
      urlObject = Uri.parse(_toCheckURL);
      hostname = urlObject.host;
    } catch (e) {
      throw SuperTokensException(e.toString());
    }

    var domain = hostname;

    if (cookieDomain == null) {
      domain = [80, 443, 0].contains(urlObject.port)
          ? domain.contains(urlObject.port.toString())
              ? hostname + ":${urlObject.port}"
              : hostname
          : hostname + ":${urlObject.port}";

      _apiDomain = NormalisedURLDomain(apiDomain).value;
      Uri apiUrlObject;
      String apiHostName;
      try {
        apiUrlObject = Uri.parse(_apiDomain);
        apiHostName = apiUrlObject.host;
      } catch (e) {
        throw SuperTokensException(e.toString());
      }

      String temp = [80, 443, 0].contains(apiUrlObject.port)
          ? apiHostName.contains(apiUrlObject.port.toString())
              ? apiHostName + ":${apiUrlObject.port}"
              : apiHostName
          : apiHostName + ":${apiUrlObject.port}";

      return domain == temp;
    } else {
      String normalisedCookieDomain =
          NormalisedInputType.normaliseSessionScopeOrThrowError(cookieDomain);
      if (cookieDomain.split(":").length > 1) {
        String portString =
            cookieDomain.split(':')[cookieDomain.split(':').length - 1];
        if (![80, 443, 0].contains(portString)) {
          normalisedCookieDomain = normalisedCookieDomain + ':' + portString;
          domain = urlObject.port == null
              ? domain
              : domain + ':' + urlObject.port.toString();
        }
      }

      if (cookieDomain.startsWith('.')) {
        return ("." + domain).endsWith(normalisedCookieDomain);
      } else {
        return domain == normalisedCookieDomain;
      }
    }
  }

  static bool doesUrlHavePort(Uri uri) {
    String scheme = uri.scheme;
    int port = uri.port;

    if (port == 0) {
      return false;
    }

    if (scheme == "http" && port == 80) {
      return false;
    }

    if (scheme == "https" && port == 443) {
      return false;
    }

    return true;
  }

  static Future<String?> getFromStorage(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    String? itemInStorage = instance.getString("st-storage-item-$name");
    return itemInStorage;
  }

  static Future<String?> getTokenForHeaderAuth(TokenType tokenType) async {
    String name = tokenType.getStorageName();
    return await getFromStorage(name);
  }

  static Future<http.BaseRequest> setAuthorizationHeaderIfRequired(
      http.BaseRequest mutableRequest,
      {bool addRefreshToken = false}) async {
    String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
    String? refreshToken = await Utils.getTokenForHeaderAuth(TokenType.REFRESH);

    if (accessToken != null && refreshToken != null) {
      if (mutableRequest.headers["Authorization"] != null) {
        //  no-op
      } else {
        String tokenToAdd = addRefreshToken ? refreshToken : accessToken;
        mutableRequest.headers["Authorization"] = "Bearer $tokenToAdd";
      }
    }
    return mutableRequest;
  }

  static Future<http.Request> setAuthorizationHeaderIfRequiredForRequestObject(
      http.Request mutableRequest,
      {bool addRefreshToken = false}) async {
    String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
    String? refreshToken = await Utils.getTokenForHeaderAuth(TokenType.REFRESH);

    if (accessToken != null && refreshToken != null) {
      if (mutableRequest.headers["Authorization"] != null) {
        //  no-op
      } else {
        String tokenToAdd = addRefreshToken ? refreshToken : accessToken;
        mutableRequest.headers["Authorization"] = "Bearer $tokenToAdd";
      }
    }
    return mutableRequest;
  }

  static void setToken(TokenType tokenType, String value) async {
    String name = tokenType.getStorageName();
    return await SuperTokensUtils.storeInStorage(name, value);
  }

  static Future<void> saveTokenFromHeaders(
      http.StreamedResponse response) async {
    Map<String, String> headers = response.headers;

    if (headers[frontTokenHeaderKey] != null) {
      await FrontToken.setItem(headers[frontTokenHeaderKey]!);
    }

    if (headers[antiCSRFHeaderKey] != null) {
      LocalSessionState localSessionState =
          await SuperTokensUtils.getLocalSessionState();

      await AntiCSRF.setToken(
          headers[antiCSRFHeaderKey]!, localSessionState.lastAccessTokenUpdate);
    }

    if (headers[ACCESS_TOKEN_NAME] != null) {
      setToken(TokenType.ACCESS, headers[ACCESS_TOKEN_NAME]!);
    }

    if (headers[REFRESH_TOKEN_NAME] != null) {
      setToken(TokenType.REFRESH, headers[REFRESH_TOKEN_NAME]!);
    }
  }
}

class NormalisedInputType {
  late String apiDomain;
  late String? apiBasePath;
  late int sessionExpiredStatusCode = 401;
  late String? sessionTokenBackendDomain;
  late SuperTokensTokenTransferMethod tokenTransferMethod;
  late String? userDefaultSuiteName;
  late Function(Eventype) eventHandler;
  late Function(APIAction, http.Request) preAPIHook;
  late Function(APIAction, http.Request, http.Response) postAPIHook;

  NormalisedInputType(
    String apiDomain,
    String? apiBasePath,
    int sessionExpiredStatusCode,
    String? sessionTokenBackendDomain,
    SuperTokensTokenTransferMethod tokenTransferMethod,
    Function(Eventype)? eventHandler,
    http.Request Function(APIAction, http.Request)? preAPIHook,
    Function(APIAction, http.Request, http.Response)? postAPIHook,
  ) {
    this.apiDomain = apiDomain;
    this.apiBasePath = apiBasePath;
    this.sessionExpiredStatusCode = sessionExpiredStatusCode;
    this.sessionTokenBackendDomain = sessionTokenBackendDomain;
    this.tokenTransferMethod = tokenTransferMethod;
    this.eventHandler = eventHandler!;
    this.preAPIHook = preAPIHook!;
    this.postAPIHook = postAPIHook!;
  }

  factory NormalisedInputType.normaliseInputType(
    String apiDomain,
    String? apiBasePath,
    int? sessionExpiredStatusCode,
    String? sessionTokenBackendDomain,
    SuperTokensTokenTransferMethod? tokenTransferMethod,
    Function(Eventype)? eventHandler,
    http.Request Function(APIAction, http.Request)? preAPIHook,
    Function(APIAction, http.Request, http.Response)? postAPIHook,
  ) {
    var _apiDOmain = NormalisedURLDomain(apiDomain);
    var _apiBasePath = NormalisedURLPath("/auth");

    if (apiBasePath != null) _apiBasePath = NormalisedURLPath(apiBasePath);

    var _sessionExpiredStatusCode = 401;
    if (sessionExpiredStatusCode != null)
      _sessionExpiredStatusCode = sessionExpiredStatusCode;

    String? _sessionTokenBackendDomain = null;
    if (sessionTokenBackendDomain != null) {
      _sessionTokenBackendDomain =
          normaliseSessionScopeOrThrowError(sessionTokenBackendDomain);
    }

    SuperTokensTokenTransferMethod _tokenTransferMethod =
        SuperTokensTokenTransferMethod.HEADER;
    if (tokenTransferMethod != null) {
      _tokenTransferMethod = tokenTransferMethod;
    }

    Function(Eventype)? _eventHandler = (_) => {};
    if (eventHandler != null) _eventHandler = eventHandler;

    http.Request Function(APIAction, http.Request)? _preAPIHook =
        (_, request) => request;
    if (preAPIHook != null) _preAPIHook = preAPIHook;

    Function(APIAction, http.Request, http.Response) _postAPIHook =
        (_, __, ___) => null;
    if (postAPIHook != null) _postAPIHook = postAPIHook;

    return NormalisedInputType(
        _apiDOmain.value,
        _apiBasePath.value,
        _sessionExpiredStatusCode,
        _sessionTokenBackendDomain,
        _tokenTransferMethod,
        _eventHandler,
        _preAPIHook,
        _postAPIHook);
  }

  static String normaliseSessionScopeOrThrowError(String sessionScope) {
    String noDotNormalised = sessionScopeHelper(sessionScope);

    if (noDotNormalised == "localhost" || Utils.isIPAddress(noDotNormalised)) {
      return noDotNormalised;
    }

    if (sessionScope.startsWith(".")) {
      return "." + noDotNormalised;
    }

    return noDotNormalised;
  }

  static String sessionScopeHelper(String SessionScope) {
    String trimmedSessionScope = SessionScope.trim();
    if (trimmedSessionScope.startsWith('.')) {
      trimmedSessionScope = trimmedSessionScope.substring(1);
    }

    if (!trimmedSessionScope.startsWith('https://') &&
        !trimmedSessionScope.startsWith('https://')) {
      trimmedSessionScope = "https://" + trimmedSessionScope;
    }

    try {
      Uri url = Uri.parse(trimmedSessionScope);
      String host = url.host;
      trimmedSessionScope = host;
      if (trimmedSessionScope.startsWith('.')) {
        trimmedSessionScope = trimmedSessionScope.substring(1);
      }
      return trimmedSessionScope;
    } catch (e) {
      throw SuperTokensException("Please provide a valid SessionScope");
    }
  }
}
