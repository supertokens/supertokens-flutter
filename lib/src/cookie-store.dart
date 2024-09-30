import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/src/logger.dart';

class SuperTokensCookieStore {
  static Map<Uri, List<Cookie>>? _allCookies;
  static SharedPreferences? _sharedPreferences;
  static final _cookieSharedPrefsKey = "supertokens-persistent-cookies";

  static final SuperTokensCookieStore _singleton =
      SuperTokensCookieStore._internal();

  factory SuperTokensCookieStore() {
    SharedPreferences.getInstance().then((value) {
      _sharedPreferences = value;
      _loadFromPersistence();
    });
    return _singleton;
  }

  SuperTokensCookieStore._internal();

  /// Loads all cookies stored in shared preferences into the in memory map [_allCookies]
  static Future<void> _loadFromPersistence() async {
    logDebugMessage('SuperTokensCookieStore._loadFromPersistence: Trying to load cookies from memory');
    _allCookies = {};
    String cookiesStringInStorage =
        _sharedPreferences?.getString(_cookieSharedPrefsKey) ?? "{}";
    Map<String, dynamic> cookiesInStorage = jsonDecode(cookiesStringInStorage);
    logDebugMessage('SuperTokensCookieStore._loadFromPersistence: cookies found: ${jsonEncode(cookiesInStorage)}');
    cookiesInStorage.forEach((key, value) {
      Uri uri = Uri.parse(key);
      List<String> cookieStrings = List.from(value);
      List<Cookie> cookies =
          cookieStrings.map((e) => Cookie.fromSetCookieValue(e)).toList();
      _allCookies?[uri] = cookies;
    });
  }

  /// Saves the provided cookie list against the provided Uri.
  ///
  /// If the cookies do not have a set domain, it defaults to the host of the provided Uri.
  ///
  /// If the cookies do not have a set path, it defaults to "/".
  ///
  /// If the provided Uri does not have a scheme, it defaults to http when saving cookies.
  ///
  /// Expired cookies are not saved.
  ///
  /// If you are trying to store cookies from a "set-cookie" header response, consider using the [saveFromSetCookieHeader] utility method which parses the header string.
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    logDebugMessage('SuperTokensCookieStore.saveFromResponse: Saving cookies against: ${uri}');
    logDebugMessage('SuperTokensCookieStore.saveFromResponse: Total passed cookies: ${cookies.length}');
    await Future.forEach<Cookie>(cookies, (element) async {
      Uri uriToStore = await _getCookieUri(uri, element);
      logDebugMessage('SuperTokensCookieStore.saveFromResponse: Setting based on uriToStore: ${uriToStore}');
      List<Cookie> currentCookies = _allCookies?[uriToStore] ?? List.from([]);
      currentCookies = currentCookies
          // ignore: unnecessary_null_comparison
          .where((e) => e != null && e.name != element.name)
          .toList();

      DateTime current = DateTime.now();
      if (element.expires != null &&
          element.expires != current &&
          element.expires!.millisecondsSinceEpoch >
              current.millisecondsSinceEpoch) {
        currentCookies.add(element);
      }

      _allCookies?[uriToStore] = currentCookies;
    });

    logDebugMessage('SuperTokensCookieStore.saveFromResponse: Removing empty cookies');
    _allCookies?.removeWhere((key, value) => value.isEmpty);

    await _updatePersistentStorage();
    await _loadFromPersistence();
  }

  /// Returns a Uri to use when saving the cookie
  Future<Uri> _getCookieUri(Uri requestUri, Cookie cookie) async {
    logDebugMessage('SuperTokensCookieStore._getCookieUri: Creating cookie uri from: ${requestUri}');
    Uri cookieUri = Uri.parse(
        // ignore: unnecessary_null_comparison
        "${requestUri.scheme == null ? "http" : requestUri.scheme}://${requestUri.host}${cookie.path == null ? "" : cookie.path}");

    if (cookie.domain != null) {
      String domain = cookie.domain ?? "";
      logDebugMessage('SuperTokensCookiesStore._getCookieUri: got domain: ${domain}');
      if (domain[0] == ".") {
        domain = domain.substring(1);
        logDebugMessage('SuperTokensCookiesStore._getCookieUri: Using domain substring: ${domain}');
      }

      try {
        cookieUri = Uri(
          // ignore: unnecessary_null_comparison
          scheme: requestUri.scheme == null ? "http" : requestUri.scheme,
          host: domain,
          path: cookie.path == null ? "/" : cookie.path,
        );
      } catch (e) {
        // Do nothing
      }
    }

    logDebugMessage('Generated cookie uri: ${cookieUri}');
    return cookieUri;
  }

  /// Uses the [_allCookies] map to update values in shared preferences.
  ///
  /// Strips expired cookies before storing in shared preferences
  Future<void> _updatePersistentStorage() async {
    logDebugMessage('SuperTokensCookieStore._updatePersistentStorage: Updating persistent storage with cookies');
    Map<String, List<String>> mapToStore = {};
    _allCookies?.forEach((key, value) {
      String uriString = key.toString();
      List<String> cookieStrings =
          List.from(value.map((e) => e.toString()).toList());
      logDebugMessage('SuperTokensCookieStore._updatePersistentStorage: Setting to ${uriString}');
      logDebugMessage('SuperTokensCookieStore._updatePersistentStorage: Setting value ${cookieStrings}');
      mapToStore[uriString] = cookieStrings;
    });

    String stringToStore = jsonEncode(mapToStore);
    logDebugMessage('SuperTokensCookieStore._updatePersistentStorage: Storing preferences: ${stringToStore}');
    await _sharedPreferences?.setString(_cookieSharedPrefsKey, stringToStore);
  }

  /// Returns a list of [Cookie]s to be sent when making requests to the provided Uri
  ///
  /// Does not return expired cookies and will remove them from persistent storage if any are found.
  ///
  /// If you are trying to add cookies to a "cookie" header for a network call, consider using the [getCookieHeaderStringForRequest] which creates a semi-colon separated cookie string for a given Uri.
  Future<List<Cookie>> getForRequest(Uri uri) async {
    logDebugMessage('SuperTokensCookieStore.getForRequest: Getting cookies for request from uri: ${uri}');
    List<Cookie> cookiesToReturn = [];
    List<Cookie> allValidCookies = [];

    if (_allCookies == null) {
      logDebugMessage('SuperTokensCookieStore.getForRequest: No cookies found');
      return cookiesToReturn;
    }

    for (Uri storedUri in _allCookies!.keys) {
      if (_doesDomainMatch(storedUri.host, uri.host) &&
          _doesPathMatch(storedUri.path, uri.path)) {
        List<Cookie> storedCookies = _allCookies?[storedUri] ?? List.from([]);
        allValidCookies.addAll(storedCookies);
      }
    }
    logDebugMessage('SuperTokensCookieStore.getForRequest: Valid cookies found: ${allValidCookies.length}');

    if (allValidCookies.isNotEmpty) {
      List<Cookie> cookiesToRemoveFromStorage = [];
      allValidCookies.forEach((element) {
        DateTime current = DateTime.now();
        if (element.expires == current ||
            (element.expires != null && element.expires!.isBefore(current))) {
          cookiesToRemoveFromStorage.add(element);
        } else {
          cookiesToReturn.add(element);
        }
      });

      logDebugMessage('SuperTokensCookieStore.getForRequest: Total cookies to remove: ${cookiesToRemoveFromStorage.length}');
      if (cookiesToRemoveFromStorage.isNotEmpty) {
        await _removeFromPersistence(uri, cookiesToRemoveFromStorage);
      }
    }

    logDebugMessage('SuperTokensCookieStore.getForRequest: Total cookies found ${cookiesToReturn.length}');
    return cookiesToReturn;
  }

  /// Checks whether a network request's domain can be considered valid for a cookie to be sent
  bool _doesDomainMatch(String cookieHost, String requestHost) {
    logDebugMessage('SuperTokensCookieStore._doesDomainMatch: Determining if domain matches');
    logDebugMessage('SuperTokensCookieStore._doesDomainMatch: cookiesHost: ${cookieHost}');
    logDebugMessage('SuperTokensCookieStore._doesDomainMatch: requestHost: ${requestHost}');
    return requestHost == cookieHost || requestHost.endsWith(".$cookieHost");
  }

  /// Checks whether a network request's path can be considered valid for a cookie to be sent
  bool _doesPathMatch(String cookiePath, String requestPath) {
    logDebugMessage('SuperTokensCookieStore._doesPathMatch: Determining if path matches');
    logDebugMessage('SuperTokensCookieStore._doesPathMatch: cookiePath: ${cookiePath}');
    logDebugMessage('SuperTokensCookieStore._doesPathMatch: requestPath: ${requestPath}');
    return (requestPath == cookiePath) ||
        (requestPath.startsWith(cookiePath) &&
            cookiePath[cookiePath.length - 1] == "/") ||
        (requestPath.startsWith(cookiePath) &&
            requestPath.substring(cookiePath.length)[0] == "/");
  }

  /// Removes a list of cookies from persistent storage
  Future<void> _removeFromPersistence(
      Uri uri, List<Cookie> cookiesToRemove) async {
    logDebugMessage('SuperTokensCookieStore._removeFromPersistence: Removing cookies from persistent storage');
    logDebugMessage('SuperTokensCookieStore._removeFromPersistence: Total cookies to remove: ${cookiesToRemove.length}');
    logDebugMessage('SuperTokensCookieStore._removeFromPersistence: uri: ${uri}');
    List<Cookie> _cookiesToRemove = List.from(cookiesToRemove);
    List<Cookie> currentCookies = _allCookies?[uri] ?? List.from([]);

    logDebugMessage('SuperTokensCookieStore._removeFromPersistence: Removing each cookie');
    _cookiesToRemove.forEach((element) {
      currentCookies.remove(element);
    });

    _allCookies?[uri] = currentCookies;
    await _updatePersistentStorage();
    await _loadFromPersistence();
    return;
  }

  /// Returns a semi-colon separated cookie string that can be used as the value for a "cookie" header in network requests for a given Uri.
  ///
  /// Does not return expired cookies and will remove them from persistent storage if any are found.
  Future<String> getCookieHeaderStringForRequest(Uri uri) async {
    logDebugMessage('SuperTokensCookieStore.getCookieHeaderStringForRequest: Getting cookie header for request from uri: ${uri}');
    List<Cookie> cookies = await getForRequest(uri);
    logDebugMessage('SuperTokensCookieStore.getCookieHeaderStringForRequest: Total cookies found: ${cookies.length}');
    // ignore: unnecessary_null_comparison
    if (cookies != null && cookies.isNotEmpty) {
      List<String> cookiesStringList =
          cookies.map((e) => e.toString()).toList();
      String cookieHeaderString = cookiesStringList.join(";");
      return cookieHeaderString;
    }

    logDebugMessage('SuperTokensCookieStore.getCookieHeaderStringForRequest: Returning empty value');
    return "";
  }

  /// Saves cookies to persistent storage using the "set-cookie" header value from network responses.
  ///
  /// If the cookies do not have a set domain, it defaults to the host of the provided Uri.
  ///
  /// If the cookies do not have a set path, it defaults to "/".
  ///
  /// If the provided Uri does not have a scheme, it defaults to http when saving cookies.
  ///
  /// Expired cookies are not saved.
  Future<void> saveFromSetCookieHeader(Uri uri, String? setCookieHeader) async {
    logDebugMessage('SuperTokensCookieStore.saveFromSetCookieHeader: Saving cookie from header against uri: ${uri}');
    if (setCookieHeader != null) {
      await saveFromResponse(uri, getCookieListFromHeader(setCookieHeader));
    }
  }

  static List<Cookie> getCookieListFromHeader(String setCookieHeader) {
    logDebugMessage('SuperTokensCookieStore.getCookieListFromHeader: Getting cookie list from header: ${setCookieHeader}');
    List<String> setCookiesStringList =
        setCookieHeader.split(RegExp(r',(?=[^ ])'));
    List<Cookie> setCookiesList =
        setCookiesStringList.map((e) => Cookie.fromSetCookieValue(e)).toList();
    logDebugMessage('SuperTokensCookieStore.getCookieListFromHeader: Total cookies found in header: ${setCookiesList.length}');
    return setCookiesList;
  }
}
