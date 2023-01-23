import 'package:http/http.dart' as http;
import 'package:supertokens/src/normalised-url-domain.dart';
import 'package:supertokens/src/normalised-url-path.dart';

import '../supertokens.dart';

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
}

class NormalisedInputType {
  late String apiDomain;
  late String? apiBasePath;
  late int sessionExpiredStatusCode = 401;
  late String? cookieDomain;
  late String? userDefaultdSuiteName;
  late Function(Eventype) eventHandler;
  late Function(APIAction, http.Request) preAPIHook;
  late Function(APIAction, http.Request, http.Response) postAPIHook;

  NormalisedInputType(
      String apiDomain,
      String? apiBasePath,
      int? sessionExpiredStatusCode,
      String? cookieDomain,
      String? userDefaultdSuiteName,
      Function(Eventype)? eventHandler,
      Function(APIAction, http.Request)? preAPIHook,
      Function(APIAction, http.Request, http.Response)? postAPIHook) {
    this.apiDomain = apiDomain;
    this.apiBasePath = apiBasePath;
    this.sessionExpiredStatusCode = sessionExpiredStatusCode ?? 401;
    this.cookieDomain = cookieDomain;
    this.userDefaultdSuiteName = userDefaultdSuiteName;
    this.eventHandler = eventHandler!;
    this.preAPIHook = preAPIHook!;
    this.postAPIHook = postAPIHook!;
  }

  factory NormalisedInputType.normaliseInputType(
    String apiDomain,
    String? apiBasePath,
    int? sessionExpiredStatusCode,
    String? cookieDomain,
    String? userDefaultdSuiteName,
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

    String? _cookieDomain = null;
    if (cookieDomain != null)
      _cookieDomain = normaliseSessionScopeOrThrowError(cookieDomain);

    Function(Eventype)? _eventHandler = (_) => {};
    if (eventHandler != null) _eventHandler = eventHandler;

    Function(APIAction, http.Request)? _preAPIHook = (_, request) => request;
    if (preAPIHook != null) _preAPIHook = preAPIHook;

    Function(APIAction, http.Request, http.Response) _postAPIHook =
        (_, __, ___) => null;
    if (postAPIHook != null) _postAPIHook = postAPIHook;

    return NormalisedInputType(
        _apiDOmain.value,
        _apiBasePath.value,
        _sessionExpiredStatusCode,
        _cookieDomain,
        userDefaultdSuiteName,
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
